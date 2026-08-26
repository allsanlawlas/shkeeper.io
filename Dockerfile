ARG PYTHON_BASE_IMAGE="python:3.13@sha256:debad600e8d6e754012528dc796488acc52438fea3d28596b87262df9b91c71e"
FROM ${PYTHON_BASE_IMAGE}

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /shkeeper.io

COPY requirements-py313.lock ./requirements-py313.lock
RUN python -m pip install --no-cache-dir --require-hashes -r requirements-py313.lock

COPY . .

CMD ["gunicorn", "--no-control-socket", "--access-logfile", "-", "--error-logfile", "-", "--workers", "1", "--threads", "16", "--worker-class", "gthread", "-b", "0.0.0.0:5000", "shkeeper:create_app()"]
