FROM python:3.12-alpine
ENV PYTHONUNBUFFERED=1
RUN adduser -D -u 10001 app
WORKDIR /app
COPY --chown=app:app app.py .
USER app
EXPOSE 8080
CMD ["python", "app.py"]
