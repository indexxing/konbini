FROM golang:1.25-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o konbini .

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/konbini .

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

EXPOSE 4444

CMD ["./konbini"]