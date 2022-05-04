FROM ruby:2.7-alpine

LABEL "org.opencontainers.image.source"="https://github.com/base2Services/cfn-guardian"

ARG GUARDIAN_VERSION="*"

COPY . /src

WORKDIR /src

RUN apk add --no-cache git \
    && gem build cfn-guardian.gemspec \
    && gem install cfn-guardian-${GUARDIAN_VERSION}.gem \
    && rm -rf /src
    
RUN addgroup -g 1000 guardian && \
    adduser -D -u 1000 -G guardian guardian

USER guardian

RUN cfndsl -u 11.5.0
