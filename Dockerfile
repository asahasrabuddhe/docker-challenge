FROM golang:1.23-alpine AS builder

ENV FILEBEAT_VERSION 5.5.0
ENV FILEBEAT_URL https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz
ENV FILEBEAT_HOME /opt/filebeat-${FILEBEAT_VERSION}-linux-x86_64
ENV PATH $PATH:$FILEBEAT_HOME

# setup filebeat
WORKDIR /opt/
RUN apk add --update curl
RUN curl -sL $FILEBEAT_URL | tar -xz -C .

# build application
COPY ./main.go /go/src
COPY ./config.yaml /go/bin
WORKDIR /go/src
RUN go build -o /go/bin/main main.go

FROM alpine:3.20

ENV FILEBEAT_VERSION 5.5.0
ENV FILEBEAT_URL https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz
ENV FILEBEAT_HOME /opt/filebeat-${FILEBEAT_VERSION}-linux-x86_64
ENV PATH $PATH:$FILEBEAT_HOME

# create non-root user
RUN addgroup -S app && adduser -S -g app app

WORKDIR /go/bin
COPY --from=builder --chown=app:app /go/bin /go/bin
COPY --from=builder --chown=app:app ${FILEBEAT_HOME} ${FILEBEAT_HOME}

USER app

# run the built server
CMD if [ $FILEBEAT_ENABLED ]; then \
        /go/bin/main 2>&1 | ${FILEBEAT_HOME}/filebeat -c  ${FILEBEAT_HOME}/config/${FILEBEAT_CONFIG} -e -v; \
    else \
        /go/bin/main 2>&1; \
    fi
