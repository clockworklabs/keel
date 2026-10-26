# Go 1.27.3 includes the crypto/x509 certificate-verification fixes.
FROM golang:1.27.3-bookworm

# Refresh CA trust after the emSign compromise, even if already installed.
RUN apt-get update && apt-get install --reinstall -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY . /go/src/github.com/keel-hq/keel
WORKDIR /go/src/github.com/keel-hq/keel
RUN make install

# Node 22.23.4 includes the October security fixes and updated CA roots.
FROM node:22.23.4-alpine

WORKDIR /app
COPY ui /app
# webpack/minifier resolutions avoid depending on OpenSSL's disabled MD4.
RUN yarn
RUN yarn run lint --no-fix
RUN yarn run build

FROM alpine:latest
# Refresh system trust to reject the compromised emSign CA.
RUN apk --no-cache add --upgrade ca-certificates

VOLUME /data
ENV XDG_DATA_HOME /data

COPY --from=0 /go/bin/keel /bin/keel
COPY --from=1 /app/dist /www
ENTRYPOINT ["/bin/keel"]
EXPOSE 9300
