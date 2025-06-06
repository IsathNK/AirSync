# 1) Choose a base image with Python 3.10 (slim variant)
FROM python:3.10-slim

# 2) Upgrade pip and install dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3) Copy your application code
COPY app.py models.py ./

# 4) Expose port 8000 (where Uvicorn will run)
EXPOSE 8000

# 5) Run Uvicorn when the container starts
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
