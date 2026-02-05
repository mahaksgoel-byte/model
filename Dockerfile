FROM python:3.11-slim

# -------------------------
# Environment
# -------------------------
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# HuggingFace & spaCy cache locations
ENV HF_HOME=/models/hf
ENV TRANSFORMERS_CACHE=/models/hf
ENV SENTENCE_TRANSFORMERS_HOME=/models/sentence_transformers
ENV SPACY_HOME=/models/spacy

# -------------------------
# System deps (minimal)
# -------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# Workdir
# -------------------------
WORKDIR /app

# -------------------------
# Install Python deps
# -------------------------
COPY requirements.txt .

# CPU-only torch
RUN pip install --no-cache-dir \
    torch==2.1.0+cpu \
    --index-url https://download.pytorch.org/whl/cpu

RUN pip install --no-cache-dir -r requirements.txt

# -------------------------
# Download NLP assets (IMPORTANT)
# -------------------------
# spaCy model
RUN python -m spacy download en_core_web_sm

# NLTK data
RUN python - <<EOF
import nltk
nltk.download('punkt')
nltk.download('wordnet')
EOF

# -------------------------
# Download HF models explicitly
# -------------------------
RUN python - <<EOF
from sentence_transformers import SentenceTransformer
from transformers import AutoTokenizer, AutoModelForSequenceClassification

# Sentence embedding model
SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

# NLI model (example – adjust to your config)
AutoTokenizer.from_pretrained("facebook/bart-large-mnli")
AutoModelForSequenceClassification.from_pretrained("facebook/bart-large-mnli")
EOF

# -------------------------
# Copy app
# -------------------------
COPY . .

# -------------------------
# Expose & run
# -------------------------
EXPOSE 8081

CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8081"]
