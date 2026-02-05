# -------------------------
# Base image (stable, small)
# -------------------------
FROM python:3.11-slim

# -------------------------
# Environment variables
# -------------------------
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV TOKENIZERS_PARALLELISM=false
ENV TRANSFORMERS_NO_ADVISORY_WARNINGS=1
ENV HF_HOME=/models

# -------------------------
# System dependencies
# -------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# Set working directory
# -------------------------
WORKDIR /app

# -------------------------
# Copy requirements
# -------------------------
COPY requirements.txt .

# -------------------------
# Install Python deps
# -------------------------
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# -------------------------
# HARD FIX: downgrade NumPy
# -------------------------
RUN pip uninstall -y numpy \
    && pip install "numpy<2"

# -------------------------
# Download spaCy model
# -------------------------
RUN pip install https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.7.1/en_core_web_sm-3.7.1-py3-none-any.whl

# -------------------------
# Pre-download ML models
# -------------------------
RUN python - <<EOF
from sentence_transformers import SentenceTransformer
from transformers import AutoTokenizer, AutoModelForSequenceClassification

# Sentence embedding model
SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

# NLI model
AutoTokenizer.from_pretrained("facebook/bart-large-mnli")
AutoModelForSequenceClassification.from_pretrained("facebook/bart-large-mnli")
EOF

# -------------------------
# Copy application code
# -------------------------
COPY . .

# -------------------------
# Expose FastAPI port
# -------------------------
EXPOSE 8080

# -------------------------
# Start FastAPI
# -------------------------
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8080"]
