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

ADD peer/Gemfile /peer/Gemfile
ADD peer/Gemfile.lock /peer/Gemfile.lock

WORKDIR /peer

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

ENV TZ Europe/Berlin

ADD docker-bin/start_peer /usr/local/bin/start_peer
RUN chmod 0755 /usr/local/bin/start_peer

WORKDIR /peer

ADD peer /peer

COPY --from=ruby_builder /usr/local/bundle /usr/local/bundle

EXPOSE 3000

CMD ["start_peer"]