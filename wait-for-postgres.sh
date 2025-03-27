#!/bin/bash
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h postgres-container -p 5432 -U postgres; do
  sleep 2
done
echo "PostgreSQL is up! Starting the application..."
exec java -jar /usr/local/lib/app.jar
