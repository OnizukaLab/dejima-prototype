FROM ruby:2.6.1-alpine as ruby_builder
MAINTAINER Yusuke-Wakuta (inherits from Dennis-Florian Herr <herrdeflo@gmail.com>)

RUN apk add --update --no-cache \
    ca-certificates \
    openssl \
    g++ \
    gcc \
    libc-dev \
    make \
    patch \
    postgresql-dev \
    ruby-dev \
    && rm -rf /var/cache/apk/*

ARG NODE

ADD "./${NODE}/Gemfile" "/${NODE}/"
ADD "./${NODE}/Gemfile.lock" "/${NODE}/"

WORKDIR "/${NODE}"

RUN bundle install 

FROM ruby:2.6.1-alpine

RUN apk add --update --no-cache \
    ca-certificates \
    openssl \
    libstdc++ \
    postgresql-dev \
    vim \
    tzdata \
    make \
    bash \
    && rm -rf /var/cache/apk/*

ARG NODE

ENV TZ Asia/Tokyo

ADD docker-bin/start_peer /usr/local/bin/start_peer
RUN chmod 0755 /usr/local/bin/start_peer

ADD "./${NODE}" "/${NODE}"

WORKDIR "/${NODE}"

COPY --from=ruby_builder /usr/local/bundle /usr/local/bundle

CMD ["start_peer"]
