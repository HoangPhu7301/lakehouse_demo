
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, IntegerType

spark = SparkSession.builder \
    .appName("HudiInitWrite") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .config("spark.sql.catalogImplementation", "hive") \
    .config("spark.sql.extensions", "org.apache.spark.sql.hudi.HoodieSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.hudi.catalog.HoodieCatalog") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "admin") \
    .config("spark.hadoop.fs.s3a.secret.key", "password") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .enableHiveSupport() \
    .getOrCreate()

# Tạo database Hive nếu chưa có
spark.sql("CREATE DATABASE IF NOT EXISTS default")

# Load dữ liệu diamonds mẫu
schema = StructType([
    StructField("id", IntegerType(), True),
    StructField("carat", DoubleType(), True),
    StructField("cut", StringType(), True),
    StructField("color", StringType(), True),
    StructField("clarity", StringType(), True),
    StructField("depth", DoubleType(), True),
    StructField("table", DoubleType(), True),
    StructField("price", IntegerType(), True),
    StructField("x", DoubleType(), True),
    StructField("y", DoubleType(), True),
    StructField("z", DoubleType(), True),
])

df = spark.read.csv("s3a://datasets/diamonds.csv", header=True, schema=schema)

# Ghi dữ liệu ra bảng Hudi và đồng bộ Hive
df.write.format("hudi") \
    .option("hoodie.table.name", "diamonds") \
    .option("hoodie.datasource.write.recordkey.field", "id") \
    .option("hoodie.datasource.write.precombine.field", "price") \
    .option("hoodie.datasource.write.table.name", "diamonds") \
    .option("hoodie.datasource.write.operation", "insert") \
    .option("hoodie.datasource.hive_sync.enable", "true") \
    .option("hoodie.datasource.hive_sync.database", "default") \
    .option("hoodie.datasource.hive_sync.table", "diamonds") \
    .option("hoodie.datasource.hive_sync.mode", "hms") \
    .option("hoodie.datasource.hive_sync.metastore.uris", "thrift://hive-metastore:9083") \
    .option("hoodie.datasource.hive_sync.support_timestamp", "true") \
    .option("path", "s3a://warehouse/hudi/default/diamonds") \
    .mode("overwrite") \
    .save()

print("✅ Done writing diamonds table to Hudi and Hive.")
spark.stop()