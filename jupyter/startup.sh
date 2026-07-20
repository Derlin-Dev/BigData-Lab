#!/bin/bash

export SPARK_HOME=/opt/spark

export PATH=$SPARK_HOME/bin:$PATH

export PYSPARK_PYTHON=python3

export PYSPARK_DRIVER_PYTHON=python3

exec jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --notebook-dir=/workspace