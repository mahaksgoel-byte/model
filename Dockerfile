FROM python:3.10-slim

# -----------------------------
# System deps (minimal)
# -----------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Set workdir
# -----------------------------
WORKDIR /app

# -----------------------------
# Copy requirements first
# (better Docker cache usage)
# -----------------------------
COPY requirements.txt .

# -----------------------------
# Install Python deps
# -----------------------------
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# -----------------------------
# Download spaCy model (BUILD TIME)
# -----------------------------
RUN python -m spacy download en_core_web_sm

# -----------------------------
# Copy app code
# -----------------------------
COPY . .

# -----------------------------
# Railway uses $PORT
# -----------------------------
ENV PORT=8080

# -----------------------------
# Start FastAPI
# -----------------------------
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8080"]
