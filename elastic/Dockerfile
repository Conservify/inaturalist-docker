FROM openjdk:8-jdk

RUN apt-get update \
	&& apt-get install -y wget \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.3.tar.gz && \
    tar -xf elasticsearch-6.2.3.tar.gz && \
    rm -f elasticsearch-6.2.3.tar.gz && \
    mv elasticsearch-6.2.3 elasticsearch

RUN cd elasticsearch && \
    bin/elasticsearch-plugin install analysis-kuromoji
