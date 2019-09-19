FROM golang:1.11.4-alpine as builder

ENV FILEBEAT_VERSION 5.5.0
ENV FILEBEAT_URL https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz
ENV FILEBEAT_HOME /opt/filebeat-${FILEBEAT_VERSION}-linux-x86_64
ENV PATH $PATH:$FILEBEAT_HOME

WORKDIR /opt/
RUN apk --no-cache add curl
RUN curl -sL $FILEBEAT_URL | tar -xz -C .

RUN addgroup -S app && adduser -S -g app app
COPY ./main.go /go/src
RUN chown -R app:app /go/src/*
RUN chown -R app:app $FILEBEAT_HOME
USER app

WORKDIR /go/src
RUN GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /go/bin/main main.go


FROM alpine:latest

ENV FILEBEAT_VERSION 5.5.0
ENV FILEBEAT_HOME /opt/filebeat-${FILEBEAT_VERSION}-linux-x86_64
ENV PATH $PATH:$FILEBEAT_HOME
COPY --from=builder $FILEBEAT_HOME $FILEBEAT_HOME 

RUN addgroup -S app && adduser -S -g app app

USER app
COPY --from=builder /go/bin/main /go/bin/main
COPY ./config.yaml /go/bin
CMD if [ $FILEBEAT_ENABLED ]; then \
        /go/bin/main 2>&1 | ${FILEBEAT_HOME}/filebeat -c  ${FILEBEAT_HOME}/config/${FILEBEAT_CONFIG} -e -v; \
    else \
        /go/bin/main 2>&1; \
    fi