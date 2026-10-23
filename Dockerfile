FROM golang:1.27.3-bookworm

RUN apt-get update && apt-get install --reinstall -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY . /go/src/github.com/keel-hq/keel
WORKDIR /go/src/github.com/keel-hq/keel
RUN make install

FROM node:22.23.4-alpine

WORKDIR /app
COPY ui /app
RUN yarn
RUN yarn run lint --no-fix
RUN yarn run build

FROM alpine:latest
RUN apk --no-cache add --upgrade ca-certificates

VOLUME /data
ENV XDG_DATA_HOME /data

COPY --from=0 /go/bin/keel /bin/keel
COPY --from=1 /app/dist /www
ENTRYPOINT ["/bin/keel"]
EXPOSE 9300
