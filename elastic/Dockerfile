FROM docker.elastic.co/elasticsearch/elasticsearch:5.6.8

COPY elasticsearch.yml /usr/share/elasticsearch/config

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-kuromoji

