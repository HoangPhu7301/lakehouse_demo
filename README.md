# Hudi-Trino-Spark-MinIO-Hive Local Environment

## 🚀 Stack

- Apache Hudi
- Apache Spark
- Apache Hive
- Trino
- MinIO

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
