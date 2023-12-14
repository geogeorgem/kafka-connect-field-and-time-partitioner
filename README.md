### Kafka Connect Field and Time Based Partitioner

####  Summary
- Partition initially by custom fields and then by time.
- It extends **[TimeBasedPartitioner](https://github.com/confluentinc/kafka-connect-storage-common/blob/master/partitioner/src/main/java/io/confluent/connect/storage/partitioner/TimeBasedPartitioner.java)**, so any existing time based partition config should be fine i.e. `path.format` will be respected.
- In order to make it work, set `"partitioner.class"="kafka.connect.storage.partitioner.FieldAndTimeBasedPartitioner"` and `"partition.field.name"="<comma separated custom fields in your record>"` in your connector config.
- Set `partition.field.format.path="false"` if you don't want to use field labels for partition names.

    ```bash
    {
        ...
        "s3.bucket.name" : "data", 
        "partition.field.name" : "appId,eventName,country",   
        "partition.field.format.path" : "true",
        "path.format": "'year'=YYYY/'month'=MM/'day'=dd",
        ...
    }          
    ```
    will produce an output in the following format : 
    
    ```bash
    /data/appId=XXXXX/eventName=YYYYYY/country=ZZ/year=2020/month=11/day=30
    ```  

####  Example

```bash

    curl http://localhost:8083/connectors -XPOST -H 'Content-type: application/json' -H 'Accept: application/json' -d '{
        "name": "connect-s3-sink-'$i'",
        "config": {     
            "topics": "events",
                "connector.class": "io.confluent.connect.s3.S3SinkConnector",
                "tasks.max" : 10,
                "flush.size": 50,
                "rotate.schedule.interval.ms": 600,
                "rotate.interval.ms": -1,
                "s3.part.size" : 5242880,
                "s3.region" : "us-east-1",
                "s3.bucket.name" : "playground-parquet-ingestion",        
                "topics.dir": "data",
                "storage.class" : "io.confluent.connect.s3.storage.S3Storage",        
                "partitioner.class": "kafka.connect.storage.partitioner.FieldAndTimeBasedPartitioner",
                "partition.field.name" : "appId,eventName",
                "partition.duration.ms" : 86400000,
                "path.format": "'year'=YYYY/'month'=MM/'day'=dd",
                "locale" : "US",
                "timezone" : "UTC",        
                "format.class": "io.confluent.connect.s3.format.parquet.ParquetFormat",
                "key.converter": "org.apache.kafka.connect.storage.StringConverter",
                "value.converter": "io.confluent.connect.avro.AvroConverter",
                "value.converter.schema.registry.url": "http://schema-registry:8081",
                "schema.compatibility": "NONE",                
                "timestamp.extractor": "RecordField",
                "timestamp.field" : "clientCreationDate",
                "parquet.codec": "snappy"                            
        }
    }'
```
Alternatively, translate the json settings to yaml file to be deployed with Confluent operator for Kubernetes (CFK)

#### Installation Guide

1. Before building make sure maven and java development kit is installed.
2. Firstly build the package using the following command `mvn package`.
3. After building the package, a new jar will be created - `target/field-and-time-partitioner-1.0.jar`. Copy the jar file into the s3 plugin directory.
4. Restart the connector if the user use helm redeploy the helm so that it can detect the plugin.

__Tips__

*Where is the plugin?*

If the plugin was installed via confluent-hub the jar file should be copied to `/usr/share/confluent-hub-components/confluentinc-kafka-connect-s3/lib/` however if kafka-connect-s3-sink was installed somewhere else place the jar file in the __same directory as the connector plugin jars__.

__Docker Container__

Use the Dockerfile in this project to create a container image which extends Confluent Kafka Connect image, installs S3 sink connector from Confluent hub, and copies the custom partitioner jar file to the required location

Sample docker build command 

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t geomge/cp-server-connect-s3-sink-custom:cp.7.5.1-s3.10.5.7_1.0 --push .
```
If you have not used a multi-arch / multi-platform build previously using buildx, execute following command to create one

```bash
docker buildx create --name mybuilder --bootstrap --use
```

