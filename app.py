import os
import sys
import json
import random
import psycopg2
from psycopg2 import pool
import requests
import boto3
from botocore.exceptions import ClientError, NoCredentialsError, EndpointConnectionError
from flask import Flask, request, jsonify, render_template
from dotenv import load_dotenv
from google import genai

# Force stdout to flush on every line instead of sitting in a buffer --
# this is exactly what hid our print() logs for hours during tonight's
# incident. Doing it here bakes the fix into the app itself instead of
# depending on whoever deploys this remembering to set PYTHONUNBUFFERED=1
# in a systemd unit, a Dockerfile, or a Kubernetes manifest.
sys.stdout.reconfigure(line_buffering=True)

load_dotenv()  # reads variables from a local .env file, if one exists

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Secrets Manager
# ---------------------------------------------------------------------------
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")


def load_secret_into_env(secret_name):
    try:
        client = boto3.client("secretsmanager", region_name=AWS_REGION)
        response = client.get_secret_value(SecretId=secret_name)
        secret_values = json.loads(response["SecretString"])
        for key, value in secret_values.items():
            os.environ[key] = value
        print(f"Loaded secret '{secret_name}' from Secrets Manager.")
    except (ClientError, NoCredentialsError, EndpointConnectionError) as exc:
        print(f"Could not load '{secret_name}' from Secrets Manager, falling back to .env: {exc}")


def load_ssm_param_into_env(param_name, env_var_name):
    try:
        client = boto3.client("ssm", region_name=AWS_REGION)
        response = client.get_parameter(Name=param_name)
        os.environ[env_var_name] = response["Parameter"]["Value"]
        print(f"Loaded '{param_name}' from SSM Parameter Store.")
    except (ClientError, NoCredentialsError, EndpointConnectionError) as exc:
        print(f"Could not load '{param_name}' from SSM, falling back: {exc}")


load_ssm_param_into_env("/icoach/questions-bank-url", "QUESTIONS_BANK_URL")

load_secret_into_env("icoach/gemini-api-key")
load_secret_into_env("icoach/db-credentials")

try:
    client = genai.Client()
except Exception as exc:
    print(f"Could not initialize Gemini client: {exc}")
    client = None

# ---------------------------------------------------------------------------
# Database connection pool
# ---------------------------------------------------------------------------
# ThreadedConnectionPool instead of SimpleConnectionPool: behaves
# identically under today's sync Gunicorn workers, but won't race if a
# future deploy switches to threaded/async workers.
try:
    db_pool = psycopg2.pool.ThreadedConnectionPool(
        1,
        5,
        host=os.environ.get("DB_HOST"),
        port=os.environ.get("DB_PORT"),
        dbname=os.environ.get("DB_NAME"),
        user=os.environ.get("DB_USER"),
        password=os.environ.get("DB_PASSWORD"),
        sslmode="require",
    )
except Exception as exc:
    print(f"Could not create database connection pool at startup: {exc}")
    db_pool = None


def get_db_connection():
    if db_pool is None:
        raise RuntimeError("Database connection pool is not available")
    return db_pool.getconn()


def release_db_connection(conn, close=False):
    if db_pool is not None and conn is not None:
        db_pool.putconn(conn, close=close)


def ensure_sessions_table():
    if db_pool is None:
        return
    try:
        conn = get_db_connection()
        try:
            cur = conn.cursor()
            cur.execute("""
                CREATE TABLE IF NOT EXISTS sessions (
                    id SERIAL PRIMARY KEY,
                    role TEXT NOT NULL,
                    question TEXT NOT NULL,
                    answer TEXT NOT NULL,
                    feedback TEXT NOT NULL,
                    created_at TIMESTAMPTZ DEFAULT now()
                );
            """)
            conn.commit()
            cur.close()
        finally:
            release_db_connection(conn)
    except Exception as exc:
        print(f"Could not ensure 'sessions' table exists: {exc}")


ensure_sessions_table()


def save_session(role, question, answer, feedback):
    conn = get_db_connection()
    try:
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO sessions (role, question, answer, feedback) VALUES (%s, %s, %s, %s)",
                (role, question, answer, feedback),
            )
            conn.commit()
            cur.close()
        except psycopg2.OperationalError:
            release_db_connection(conn, close=True)
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO sessions (role, question, answer, feedback) VALUES (%s, %s, %s, %s)",
                (role, question, answer, feedback),
            )
            conn.commit()
            cur.close()
    finally:
        release_db_connection(conn)


ROLES = {
    "cloud-engineer": "Cloud Engineer",
    "software-engineer": "Software Engineer",
    "data-analyst": "Data Analyst",
    "product-manager": "Product Manager",
}

QUESTIONS_URL = os.environ.get("QUESTIONS_BANK_URL")


def load_question_bank():
    try:
        response = requests.get(QUESTIONS_URL, timeout=5)
        response.raise_for_status()
        return response.json()
    except Exception as exc:
        print(f"Could not load question bank from CloudFront: {exc}")
        return {
            "cloud-engineer": [
                "Walk me through how you would design a highly available web app on AWS."
            ],
            "software-engineer": [
                "Tell me about a time you had to debug a difficult issue in production."
            ],
            "data-analyst": [
                "Walk me through how you'd investigate a sudden drop in a key metric."
            ],
            "product-manager": [
                "How do you prioritize a backlog when everything feels urgent?"
            ],
        }


QUESTION_BANK = load_question_bank()


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/health")
def health():
    # Liveness: is the process alive. Stays shallow on purpose -- this
    # should never fail just because the DB or Gemini had a blip.
    return jsonify({"status": "ok"}), 200


@app.route("/ready")
def ready():
    # Readiness: can this pod actually serve a real request right now.
    # For Kubernetes -- not used yet on plain ALB, but ready for EKS.
    if db_pool is None or client is None:
        return jsonify({"status": "not ready"}), 503
    return jsonify({"status": "ready"}), 200


@app.route("/api/roles")
def get_roles():
    return jsonify(ROLES)


@app.route("/api/question", methods=["POST"])
def get_question():
    data = request.get_json(silent=True) or {}
    role = data.get("role")
    if role not in QUESTION_BANK:
        return jsonify({"error": "Unknown role"}), 400
    question = random.choice(QUESTION_BANK[role])
    return jsonify({"question": question})


@app.route("/api/feedback", methods=["POST"])
def get_feedback():
    data = request.get_json(silent=True) or {}
    role = data.get("role")
    question = data.get("question")
    answer = data.get("answer")

    if not all([role, question, answer]):
        return jsonify({"error": "Missing role, question, or answer"}), 400

    if client is None:
        return jsonify({"error": "Could not reach the AI service. Please try again."}), 500

    role_label = ROLES.get(role, role)

    prompt = (
        f"You are a supportive interview coach for a {role_label} role.\n\n"
        f"Interview question: {question}\n\n"
        f"Candidate's answer: {answer}\n\n"
        "Give short, specific feedback in 3-5 sentences: one thing they did well, "
        "one thing to improve, and a concrete tip for structuring the answer better "
        "(e.g. the STAR method)."
    )

    try:
        response = client.models.generate_content(
            model="gemini-3.5-flash",
            contents=prompt,
        )
        feedback = response.text
        save_session(role, question, answer, feedback)
    except Exception as exc:
        print(f"Error in get_feedback: {exc}")
        return jsonify({"error": "Could not reach the AI service. Please try again."}), 500

    return jsonify({"feedback": feedback})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    host = os.environ.get("HOST", "0.0.0.0")
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    app.run(host=host, port=port, debug=debug)