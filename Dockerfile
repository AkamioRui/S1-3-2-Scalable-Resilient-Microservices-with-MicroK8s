# existing image
FROM mariadb:11

# default credential for testing
ENV MARIADB_DATABASE=stockdb
ENV MARIADB_USER=stockuser
ENV MARIADB_PASSWORD=stockpassword
ENV MARIADB_ROOT_PASSWORD=rootpassword

# Copy initialization script
COPY init.sql /docker-entrypoint-initdb.d/init.sql

# MariaDB default port
EXPOSE 3306