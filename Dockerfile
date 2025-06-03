
FROM python:3.12-slim
WORKDIR /app
COPY backend/ .
RUN pip install fastapi uvicorn sqlalchemy pydantic psycopg2-binary python-multipart
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
