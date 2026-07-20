FROM apache/spark:3.5.3

USER root

RUN apt-get update && \
    apt-get install -y \
        curl \
        nano \
        procps && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip setuptools wheel

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

COPY startup.sh /opt/startup.sh

RUN chmod +x /opt/startup.sh

RUN mkdir -p /workspace && \
    chown -R spark:spark /workspace

# Crear home de spark para Jupyter
RUN mkdir -p /home/spark/.local/share/jupyter/runtime && \
    chown -R spark:spark /home/spark

ENV HOME=/home/spark
ENV JUPYTER_RUNTIME_DIR=/home/spark/.local/share/jupyter/runtime

USER spark

ENTRYPOINT ["/opt/startup.sh"]