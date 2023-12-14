FROM confluentinc/cp-server-connect:7.5.1
USER root
RUN  confluent-hub install --no-prompt confluentinc/kafka-connect-s3:10.5.7
ADD target/field-and-time-partitioner-1.0.jar /usr/share/confluent-hub-components/confluentinc-kafka-connect-s3/lib/
USER 1001

