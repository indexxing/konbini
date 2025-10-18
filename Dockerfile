# Build stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o konbini .

# -----------------

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/konbini .

# Create the did.json file with the specified content
RUN echo '{ \
  "@context": [ \
    "https://www.w3.org/ns/did/v1", \
    "https://w3id.org/security/multikey/v1" \
  ], \
  "id": "did:web:api.bsky.indexx.dev", \
  "verificationMethod": [ \
    { \
      "id": "did:web:bsky.indexx.dev#atproto", \
      "type": "Multikey", \
      "controller": "did:web:api.bsky.indexx.dev", \
      "publicKeyMultibase": "zQ3shTX4EtEXJHcENR4DW38rZLLRN46s9peYJfeDfzUAKK98j" \
    } \
  ], \
  "service": [ \
    { \
      "id": "#bsky_notif", \
      "type": "BskyNotificationService", \
      "serviceEndpoint": "https://api.bsky.indexx.dev" \
    }, \
    { \
      "id": "#bsky_appview", \
      "type": "BskyAppView", \
      "serviceEndpoint": "https://api.bsky.indexx.dev" \
    } \
  ] \
}' > did.json

# Expose the API port
EXPOSE 4444

CMD ["./konbini"]