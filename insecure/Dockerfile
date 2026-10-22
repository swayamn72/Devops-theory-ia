# INSECURE version: old base image + old dependencies + runs as root.
# Used only to demonstrate Trivy failing the pipeline.
FROM python:3.7

WORKDIR /srv
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app ./app
EXPOSE 5000
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app.app:app"]
