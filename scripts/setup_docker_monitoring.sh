#!/bin/bash
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common git

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

rm -rf smartoffice
git clone https://github.com/supermedmed-hash/B3_MFA_ILYES_OCEANE.git smartoffice
cd smartoffice

cat << 'EOF' > docker-compose.monitoring.yml
services:
  zabbix-db:
    image: mariadb:11.3
    container_name: smartoffice_zabbix_db
    environment:
      - MARIADB_USER=zabbix
      - MARIADB_PASSWORD=zabbix_pass
      - MARIADB_ROOT_PASSWORD=root_pass
      - MARIADB_DATABASE=zabbix
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_bin --log-bin-trust-function-creators=1
    volumes:
      - zabbix-db-data:/var/lib/mysql
    networks:
      - smartoffice-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s

  zabbix-server:
    image: zabbix/zabbix-server-mysql:ubuntu-latest
    container_name: smartoffice_zabbix_server
    depends_on:
      zabbix-db:
        condition: service_healthy
    environment:
      - DB_SERVER_HOST=zabbix-db
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=zabbix_pass
      - MYSQL_DATABASE=zabbix
      - MYSQL_ROOT_PASSWORD=root_pass
    ports:
      - "10051:10051"
    networks:
      - smartoffice-net
    restart: unless-stopped

  zabbix-web:
    image: zabbix/zabbix-web-nginx-mysql:ubuntu-latest
    container_name: smartoffice_zabbix_web
    depends_on:
      zabbix-db:
        condition: service_healthy
      zabbix-server:
        condition: service_started
    environment:
      - DB_SERVER_HOST=zabbix-db
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=zabbix_pass
      - MYSQL_DATABASE=zabbix
      - MYSQL_ROOT_PASSWORD=root_pass
      - ZBX_SERVER_HOST=zabbix-server
      - PHP_TZ=Europe/Paris
    ports:
      - "8080:8080"
    networks:
      - smartoffice-net
    restart: unless-stopped

  grafana:
    image: grafana/grafana-oss:latest
    container_name: smartoffice_grafana
    depends_on:
      zabbix-server:
        condition: service_started
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=alexanderzobnin-zabbix-app
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources
      - ./monitoring/grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards/files
    networks:
      - smartoffice-net
    restart: unless-stopped

networks:
  smartoffice-net:
    driver: bridge

volumes:
  zabbix-db-data:
  grafana-data:
EOF

sudo docker-compose -f docker-compose.monitoring.yml up -d
