FROM apache/hive:4.0.1

USER root

RUN apt-get update && \
    apt-get install -y procps curl nano && \
    rm -rf /var/lib/apt/lists/*

# Driver JDBC PostgreSQL
COPY lib/postgresql-42.7.12.jar /opt/hive/lib/

# Configuración Hive
COPY conf /opt/hive/conf

# Scripts
COPY scripts /opt/hive/scripts

RUN chmod +x /opt/hive/scripts/entrypoint.sh

USER hive

ENTRYPOINT ["/opt/hive/scripts/entrypoint.sh"]