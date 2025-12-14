FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY main.go .
RUN go mod init error-generator && go build -o error-generator main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/error-generator .

EXPOSE 4000

CMD ["./error-generator"]

