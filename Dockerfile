# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.13.0a4
FROM python:${PYTHON_VERSION}-alpine3.19 as base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser

# Install necessary build tools and dependencies
RUN apk update && \
    apk add --no-cache build-base musl-dev python3-dev

# Install Python packages from requirements.txt
COPY requirements.txt /app/requirements.txt
RUN python3 -m pip install --no-cache-dir -r requirements.txt

# Switch to the non-privileged user to run the application.
USER appuser

# Copy the source code(counter-service.py) into the container.
COPY counter-service.py .

# Expose the port that the application listens on.
EXPOSE 8080

# Run the application
CMD ["gunicorn", "counter-service:app", "--bind", "0.0.0.0:8080", "--access-logfile", "-", "--error-logfile", "-"]
