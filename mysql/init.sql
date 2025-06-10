-- This file will be executed when MySQL container starts for the first time
-- The MYSQL_DATABASE=hive_metastore, MYSQL_USER=hive, MYSQL_PASSWORD=hive 
-- environment variables automatically create the database and user

-- Switch to the hive_metastore database
USE hive_metastore;


GRANT ALL ON metastore_db.* TO 'hive'@'%';

-- Create a simple test table to verify the database is working
CREATE TABLE IF NOT EXISTS connection_test (
    id INT PRIMARY KEY AUTO_INCREMENT,
    test_message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert a test record
INSERT INTO connection_test (test_message) VALUES ('MySQL initialized successfully for Hive Metastore');

-- Show that everything is working
SELECT 'Database initialization completed' AS status;