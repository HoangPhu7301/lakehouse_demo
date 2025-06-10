# Hudi-Trino-Spark-MinIO-Hive Local Environment

## 🚀 Stack

- Apache Hudi
- Apache Spark
- Apache Hive
- Trino
- MinIO

# Dependencies Setup

## Large files excluded from repository

### Required downloads:

1. **Apache Hive 3.1.3**
   ```bash
   wget https://archive.apache.org/dist/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz
   tar -xzf apache-hive-3.1.3-bin.tar.gz

copy all jar file to hive/lib to run 
2. **Hadoop 3.3.4**
wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz
tar -xzf hadoop-3.3.4.tar.gz

make sure you allow the script when done download the dependencies "chmod -R 755 hadoop-3.3.4/"
## 🛠️ How to Run

```bash
docker-compose up -d
docker exec -it spark spark-submit \
  --packages org.apache.hudi:hudi-spark3.4-bundle_2.12:0.14.1 \
  /script/hudi_spark_script.py
docker exec -it hive-metastore bash
docker exec -it trino trino
```

## 🔍 Query in Trino

Go to http://localhost:8080 and run:

```sql
show catalogs;
show schemas from hudi;
SELECT * FROM hudi.default.diamonds;
SELECT * FROM hive.default.diamonds LIMIT 5;
```