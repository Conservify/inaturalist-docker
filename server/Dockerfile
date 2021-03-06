FROM ubuntu:16.04

RUN apt-get update \
	&& apt-get install -y git ruby ruby-dev build-essential zlib1g zlib1g-dev libpq-dev wget curl tzdata postgresql-client libgeos-dev libgeos++-dev libproj-dev locales imagemagick libimage-exiftool-perl \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh && \
    bash nodesource_setup.sh

RUN apt-get install -y nodejs

RUN git clone https://github.com/inaturalist/inaturalist.git

WORKDIR /app/inaturalist

RUN cp config/config.yml.example config/config.yml && \
    cp config/secrets.yml.example config/secrets.yml && \
    cp config/smtp.yml.example config/smtp.yml

ENV RUBYOPT "-KU -E utf-8:utf-8"

RUN gem install bundler
RUN gem install tzinfo-data
RUN bundle
RUN npm install
RUN node_modules/.bin/gulp webpack

RUN dpkg-reconfigure locales -f noninteractive && \
    locale-gen en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

COPY database.yml config
COPY config.yml config

COPY startup.sh .
COPY startup.sql .

RUN chmod 755 startup.sh

CMD [ "./startup.sh" ]
