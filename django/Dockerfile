# Use an official Python runtime as a parent image
FROM python:3.11.4-slim-buster

# Environment variables (optional)
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip -r requirements.txt

# Copy your Django project
COPY . .

# Install Gunicorn
RUN pip install gunicorn

# Expose the port
EXPOSE 8000

# Run Gunicorn, binding to 0.0.0.0 for external access
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "backend.wsgi"]
