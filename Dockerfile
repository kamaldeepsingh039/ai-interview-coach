FROM python:3.12-slim

WORKDIR /app

# Install dependencies first so Docker can cache this layer
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the rest of the app
COPY . .

ENV PORT=5000
EXPOSE 5000

# We do NOT set GEMINI_API_KEY here — it gets passed in at runtime
# (docker run -e GEMINI_API_KEY=... or, in AWS, from Secrets Manager / SSM)
CMD ["python", "app.py"]
