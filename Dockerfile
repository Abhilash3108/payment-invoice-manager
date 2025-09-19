# Stage 1: Build the Go binary
FROM golang:1.25-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download && go mod verify
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o bin/app ./cmd/app

# Stage 2: Runtime image with migrations tool
FROM alpine:latest
# Install runtime dependencies and migrate CLI
RUN apk add --no-cache ca-certificates tzdata postgresql-client curl && \
    update-ca-certificates && \
    curl -L https://github.com/golang-migrate/migrate/releases/latest/download/migrate.linux-amd64.tar.gz \
      | tar xz && mv migrate /usr/local/bin/

# Create non-root user and app dir
RUN addgroup -S appgroup && adduser -S -G appgroup appuser && \
    mkdir /app && chown appuser:appgroup /app

USER appuser
WORKDIR /app

# Copy binary and migrations
COPY --from=builder --chown=appuser:appgroup /app/bin/app ./app
COPY --from=builder --chown=appuser:appgroup /app/migrations ./migrations

EXPOSE 8080

# Entrypoint script to run migrations then start app
RUN printf '#!/bin/sh\n\
echo "Waiting for database..."\n\
while ! nc -z $DB_HOST $DB_PORT; do sleep 1; done\n\
echo "Applying migrations..."\n\
migrate -path ./migrations -database "postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=disable" up\n\
echo "Starting application..."\n\
exec ./app\n' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
