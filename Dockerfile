# syntax=docker/dockerfile:1.7

ARG GO_VERSION=1.22

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS builder

ENV CGO_ENABLED=0 \
    GOFLAGS="-trimpath" \
    GOPROXY=https://proxy.golang.org,direct

WORKDIR /src

RUN apk add --no-cache git ca-certificates tzdata && \
    adduser -D -g '' -u 65532 nonroot

COPY go.mod go.sum* ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev
ARG COMMIT=none
ARG BUILD_DATE=unknown

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build \
        -ldflags="-s -w \
            -X main.version=${VERSION} \
            -X main.commit=${COMMIT} \
            -X main.date=${BUILD_DATE}" \
        -o /out/notar ./cmd/notar

FROM gcr.io/distroless/static-debian12:nonroot AS runtime

LABEL org.opencontainers.image.source="https://github.com/im5tu/notar" \
      org.opencontainers.image.title="notar" \
      org.opencontainers.image.description="notar" \
      org.opencontainers.image.licenses="MIT"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /out/notar /usr/local/bin/notar

USER nonroot:nonroot

ENTRYPOINT ["/usr/local/bin/notar"]
