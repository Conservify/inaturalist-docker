FROM ubuntu:16.04

RUN apt-get update \
	&& apt-get install -y git build-essential zlib1g zlib1g-dev libpq-dev wget curl \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh && \
    bash nodesource_setup.sh

RUN apt-get install -y nodejs

RUN git clone https://github.com/inaturalist/iNaturalistAPI.git

WORKDIR /app/iNaturalistAPI

RUN npm install

COPY config.js .

CMD [ "node", "app.js" ]
