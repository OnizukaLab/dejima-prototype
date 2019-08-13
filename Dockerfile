FROM ruby:2.6.1 as ruby_builder
MAINTAINER Yusuke-Wakuta (inherits from Dennis-Florian Herr <herrdeflo@gmail.com>)

RUN apt-get update
RUN apt-get install -y \
    ca-certificates \
    openssl \
    g++ \
    build-essential \
    libc-dev \
    make \
    patch \
    postgresql \
    ruby-dev

ARG NODE

ADD "./${NODE}/Gemfile" "/${NODE}/"
ADD "./${NODE}/Gemfile.lock" "/${NODE}/"

WORKDIR "/${NODE}"

RUN bundle install 

FROM ruby:2.6.1

RUN apt-get update
RUN apt-get install -y \
    ca-certificates \
    openssl \
    g++ \
    build-essential \
    libc-dev \
    make \
    patch \
    postgresql \
    ruby-dev

ARG NODE

ENV TZ Asia/Tokyo

ADD docker-bin/start_peer /usr/local/bin/start_peer
RUN chmod 0755 /usr/local/bin/start_peer

ADD "./${NODE}" "/${NODE}"

WORKDIR "/${NODE}"

COPY --from=ruby_builder /usr/local/bundle /usr/local/bundle

CMD ["start_peer"]
