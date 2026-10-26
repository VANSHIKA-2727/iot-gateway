FROM alpine:3.22
RUN apk add --no-cache python3
WORKDIR /app
COPY docker/server.py /app/server.py
EXPOSE 80
ENV PYTHONUNBUFFERED=1
CMD ["python3", "/app/server.py"]
