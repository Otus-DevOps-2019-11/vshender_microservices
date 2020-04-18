FROM golang:1.14.2-alpine AS build-binary

RUN apk add --no-cache git=2.24.2-r0 make=4.2.1-r2
RUN go get -u github.com/percona/mongodb_exporter

WORKDIR /go/src/github.com/percona/mongodb_exporter
RUN make build


FROM alpine:3.11.5

EXPOSE 9216

COPY --from=build-binary /go/src/github.com/percona/mongodb_exporter/bin/mongodb_exporter /bin/mongodb_exporter

ENV MONGODB_URI=mongodb://db:27017

ENTRYPOINT ["/bin/mongodb_exporter"]
