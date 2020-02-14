FROM golang:1.13.8-alpine

ENV FILEBEAT_VERSION 5.5.0
ENV FILEBEAT_URL https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz
ENV FILEBEAT_HOME /opt/filebeat-${FILEBEAT_VERSION}-linux-x86_64
ENV PATH $PATH:$FILEBEAT_HOME

WORKDIR /opt/
RUN apk add --update curl
RUN curl -sL $FILEBEAT_URL | tar -xz -C .

# create non-root user
RUN addgroup -S app && adduser -S -g app app
COPY ./main.go /go/src
COPY ./config.yaml /go/bin
RUN chown -R app:app /go/src/*
RUN chown -R app:app $FILEBEAT_HOME
USER app

WORKDIR /go/src
RUN go build -o /go/bin/main main.go

# run the built server
CMD if [ $FILEBEAT_ENABLED ]; then \
        /go/bin/main 2>&1 | ${FILEBEAT_HOME}/filebeat -c  ${FILEBEAT_HOME}/config/${FILEBEAT_CONFIG} -e -v; \
    else \
        /go/bin/main 2>&1; \
    fi

