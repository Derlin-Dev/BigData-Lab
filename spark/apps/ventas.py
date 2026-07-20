from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("Lectura HDFS")
    .getOrCreate()
)

print("=" * 60)
print("Leyendo archivo desde HDFS")
print("=" * 60)

df = spark.read.text("/datasets/prueba.txt")

df.show(truncate=False)

spark.stop()