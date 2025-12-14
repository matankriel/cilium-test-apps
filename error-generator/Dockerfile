# CONFIGURATION REQUIRED FOR DISCONNECTED ENV:
# Replace with your private Artifactory registry mirrors for base images
# Example: FROM artifactory.yourcompany.local/docker/golang:1.21-alpine AS builder
# Or configure Docker daemon to use registry mirror (recommended)
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY main.go .
RUN go mod init error-generator && go build -o error-generator main.go

# CONFIGURATION REQUIRED FOR DISCONNECTED ENV:
# Replace with your private Artifactory registry mirror for Alpine base image
# Example: FROM artifactory.yourcompany.local/docker/alpine:latest
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/error-generator .

EXPOSE 4000

CMD ["./error-generator"]

