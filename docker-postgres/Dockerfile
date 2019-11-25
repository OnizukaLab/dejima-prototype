FROM postgres:11.2-alpine
MAINTAINER Dennis-Florian Herr <herrdeflo@gmail.com>

RUN apk add --update --no-cache \
    build-base \
    bash \
    curl \
    git \
    make \
  && rm -rf /var/cache/apk/*

RUN git clone https://github.com/petere/plsh \
  && cd plsh && git checkout 9b108516a005a0592d9c9e145189825f92f820e1 \
  && make && make install

COPY add_dejima_user.sh /docker-entrypoint-initdb.d/add_dejima_user.sh
COPY postgresql.conf /etc/postgresql.conf

CMD ["postgres", "-c", "config_file=/etc/postgresql.conf"]

