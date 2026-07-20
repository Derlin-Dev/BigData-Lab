FROM apache/spark:3.5.3

USER root

RUN apt-get update && \
    apt-get install -y python3-pip curl nano procps && \
    rm -rf /var/lib/apt/lists/*

COPY conf/spark-defaults.conf /opt/spark/conf/spark-defaults.conf
COPY conf/log4j2.properties /opt/spark/conf/log4j2.properties

COPY apps /opt/spark/apps

RUN chmod -R 755 /opt/spark/apps && \
    chown -R spark:spark /opt/spark/conf \
    /opt/spark/apps

USER spark