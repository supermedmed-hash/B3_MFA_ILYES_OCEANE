#!/bin/bash
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common git jq

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

rm -rf smartoffice
git clone https://github.com/supermedmed-hash/B3_MFA_ILYES_OCEANE.git smartoffice
cd smartoffice

cat << 'EOF' > docker-compose.app.yml
services:
  web-app:
    build: ./app-reservation
    container_name: smartoffice_web
    ports:
      - "3000:3000"
      - "80:3000"
    environment:
      - PORT=3000
      - POSTGRES_USER=admin_postgres
      - POSTGRES_PASSWORD=secret_postgres
      - POSTGRES_DB=smartoffice
      - POSTGRES_HOST=db-postgres
      - MONGO_URI=mongodb://db-mongo:27017/smartoffice_iot
    depends_on:
      - db-postgres
      - db-mongo
    networks:
      - smartoffice-net
    restart: always

  db-postgres:
    image: postgres:15-alpine
    container_name: smartoffice_postgres
    environment:
      - POSTGRES_USER=admin_postgres
      - POSTGRES_PASSWORD=secret_postgres
      - POSTGRES_DB=smartoffice
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - smartoffice-net
    restart: unless-stopped

  db-mongo:
    image: mongo:6
    container_name: smartoffice_mongo
    ports:
      - "27017:27017"
    volumes:
      - mongodata:/data/db
    networks:
      - smartoffice-net
    restart: unless-stopped

networks:
  smartoffice-net:
    driver: bridge

volumes:
  pgdata:
  mongodata:
EOF

sudo docker-compose -f docker-compose.app.yml up -d --build
