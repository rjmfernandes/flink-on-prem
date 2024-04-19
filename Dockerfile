FROM flink:latest
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.1.0-1.18/flink-sql-connector-kafka-3.1.0-1.18.jar
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/org/apache/flink/flink-avro-confluent-registry/1.19.0/flink-avro-confluent-registry-1.19.0.jar
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/org/apache/avro/avro/1.11.3/avro-1.11.3.jar
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/org/apache/flink/flink-avro/1.19.0/flink-avro-1.19.0.jar
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.17.0/jackson-databind-2.17.0.jar
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-core/2.17.0/jackson-core-2.17.0.jar
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.17.0/jackson-annotations-2.17.0.jar
RUN wget -P /opt/flink/lib https://packages.confluent.io/maven/io/confluent/kafka-schema-registry-client/7.6.0/kafka-schema-registry-client-7.6.0.jar
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.7.0/kafka-clients-3.7.0.jar
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/com/google/guava/guava/12.0/guava-12.0.jar
