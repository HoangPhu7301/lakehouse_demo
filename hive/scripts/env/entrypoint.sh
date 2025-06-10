#!/bin/bash
set -e

# Cài netcat nếu cần
if ! command -v nc &> /dev/null; then
    echo "Installing netcat..."
    apt-get update && apt-get install -y netcat-openbsd
fi

# Function to test MySQL connection without mysql client
test_mysql_connection_nc() {
    local host=$1
    local port=$2
    local timeout=${3:-5}
    
    if timeout $timeout bash -c "</dev/tcp/$host/$port"; then
        return 0
    else
        return 1
    fi
}

echo "Waiting for MySQL to be ready..."
# Wait for MySQL port to be open
for i in {1..60}; do
    if nc -z metastore-db 3306; then
        echo "MySQL port is open"
        break
    fi
    echo "MySQL not ready, waiting... ($i/60)"
    sleep 2
done

# Additional wait for MySQL to fully initialize
echo "Waiting additional time for MySQL initialization..."
sleep 15

# Set environment variables
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hive/conf
export HIVE_HOME=/opt/hive
export HADOOP_CLASSPATH="/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hive/lib/*"
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin


# if ! ls $HIVE_HOME/lib/mysql-connector-j-*.jar >/dev/null 2>&1; then
#     echo "❌ Missing MySQL JDBC driver in $HIVE_HOME/lib"
#     exit 1
# fi

echo "🔍 Checking Hive Metastore schema..."
set +e
$HIVE_HOME/bin/schematool -dbType mysql --info >/dev/null 2>&1
INFO_STATUS=$?
set -e

if [ $INFO_STATUS -eq 0 ]; then
    echo "✅ Hive schema already initialized"
else
    echo "⚙️  Initializing Hive Metastore schema..."
    $HIVE_HOME/bin/schematool -dbType mysql --initSchema --verbose
    echo "✅ Hive Metastore schema initialization complete"
fi

# Function to test MySQL connection using HTTP-like approach
test_mysql_connection() {
    local user=$1
    local password=$2
    local database=${3:-""}
    
    # Since we don't have mysql client, we'll rely on the Java connection test
    # This will be tested when Hive actually starts
    return 0
}

# Test MySQL connection using netcat (port test only)
echo "Testing MySQL connection (port connectivity)..."
ROOT_CONNECTION_SUCCESS=false
for i in {1..10}; do
    if test_mysql_connection_nc "metastore-db" "3306" 10; then
        echo "✓ MySQL port is accessible (attempt $i)"
        ROOT_CONNECTION_SUCCESS=true
        break
    else
        echo "MySQL port not accessible, attempt $i/10, waiting..."
        sleep 5
    fi
done

if [ "$ROOT_CONNECTION_SUCCESS" = false ]; then
    echo "ERROR: Cannot connect to MySQL port after 10 attempts!"
    echo "Checking if metastore-db container is running..."
    exit 1
fi

echo "Skipping manual MySQL user setup (will be handled by MySQL init and Hive auto-connection)"

echo "Testing basic connectivity to MySQL..."
if test_mysql_connection_nc "metastore-db" "3306" 5; then
    echo "✓ MySQL port connectivity confirmed"
else
    echo "ERROR: Cannot connect to MySQL port!"
    exit 1
fi


echo "Skipping schema check - will rely on Hive's autoCreateSchema feature"
echo "Database schema will be created automatically when Hive Metastore starts"

# Skip table verification since we don't have mysql client
echo "Skipping table verification - tables will be created automatically by Hive"

# Final connectivity test
echo "Final connectivity test..."
if ! test_mysql_connection_nc "metastore-db" "3306" 5; then
    echo "ERROR: Final connectivity test failed!"
    exit 1
fi

echo "All checks passed! Starting Hive Metastore service..."
echo "Service will be available on port 9083"

# Start Hive Metastore with proper logging
exec $HIVE_HOME/bin/hive --service metastore --verbose