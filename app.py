import os
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

load_dotenv()  # reads variables from a local .env file, if one exists

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Secrets Manager
# ---------------------------------------------------------------------------
# On the app-tier EC2 instance, this pulls the real Gemini API key and DB
# credentials from Secrets Manager and drops them into the environment,
# using whatever IAM role is attached to the instance -- no AWS access keys
# ever live in this file or in .env.
#
# On a laptop with no IAM role attached, the AWS call fails fast and this
# silently falls back to whatever's already in .env, same fallback pattern
# already used below in load_question_bank() for CloudFront.
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

# Secret names created in AWS Secrets Manager -- see SECRETS_MANAGER_SETUP.md
# for the exact key/value pairs each one needs to contain.
load_secret_into_env("icoach/gemini-api-key")
load_secret_into_env("icoach/db-credentials")

# The Gemini client reads the GEMINI_API_KEY environment variable automatically.
# We never put the key in this file -- that's the whole point of using env vars.
# Gemini's free tier needs no credit card on file, so there is no path to a
# surprise bill here -- worst case, requests get rate-limited, not charged.
#
# Wrapped in try/except: if the secret above failed to load for any reason
# (missing, wrong permissions, not created yet), this would otherwise crash
# the whole app on startup instead of just degrading the feedback feature.
try:
    client = genai.Client()
except Exception as exc:
    print(f"Could not initialize Gemini client: {exc}")
    client = None

# ---------------------------------------------------------------------------
# Database connection pool
# ---------------------------------------------------------------------------
# Replaces opening a brand-new Postgres connection on every single request.
# minconn=1: at least one connection stays open and ready at all times.
# maxconn=5: caps how many connections *this one process* can hold at once,
# so a traffic spike can't exhaust RDS's total connection limit by itself.
#
# Wrapped in try/except for the same reason as the Gemini client above: a
# database outage at startup should degrade the /api/feedback route only,
# not crash the whole app and fail every ALB health check.
try:
    db_pool = psycopg2.pool.SimpleConnectionPool(
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


def release_db_connection(conn):
    if db_pool is not None and conn is not None:
        db_pool.putconn(conn)


ROLES = {
    "cloud-engineer": "Cloud Engineer",
    "software-engineer": "Software Engineer",
    "data-analyst": "Data Analyst",
    "product-manager": "Product Manager",
}

# Question bank lives in S3, served through CloudFront, instead of being
# hardcoded here. This fetch runs once, when Flask starts up.
QUESTIONS_URL = os.environ.get("QUESTIONS_BANK_URL")


def load_question_bank():
    try:
        response = requests.get(QUESTIONS_URL, timeout=5)
        response.raise_for_status()
        return response.json()
    except Exception as exc:
        print(f"Could not load question bank from CloudFront: {exc}")
        # Small emergency fallback so the app still runs if CloudFront is
        # ever unreachable, instead of crashing on startup.
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
    return jsonify({"status": "ok"}), 200


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
            # Free-tier model with a generous daily quota -- good for a learning project.
            # "gemini-3.5-flash" gives deeper feedback but only ~50 free requests/day.
            model="gemini-3.5-flash",
            contents=prompt,
        )
        feedback = response.text

        conn = get_db_connection()
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO sessions (role, question, answer, feedback) VALUES (%s, %s, %s, %s)",
                (role, question, answer, feedback),
            )
            conn.commit()
            cur.close()
        finally:
            release_db_connection(conn)
    except Exception as exc:
        # Full detail logged server-side for debugging; client gets a generic
        # message only, so internal errors are never exposed over the API.
        print(f"Error in get_feedback: {exc}")
        return jsonify({"error": "Could not reach the AI service. Please try again."}), 500

    return jsonify({"feedback": feedback})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    host = os.environ.get("HOST", "127.0.0.1")
    debug = os.environ.get("FLASK_DEBUG", "true").lower() == "true"
    app.run(host="0.0.0.0", port=port, debug=debug)
