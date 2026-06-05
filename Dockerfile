# existing image
FROM postgres:16-alpine

# default credential for testing
ENV POSTGRES_DB=stockdb
ENV POSTGRES_USER=stockuser
ENV POSTGRES_PASSWORD=stockpassword

# copies init.sql from local machine
COPY init.sql /docker-entrypoint-initdb.d/init.sql

# PostgreSQL default port
EXPOSE 5432