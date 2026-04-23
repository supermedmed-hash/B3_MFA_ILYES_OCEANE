# 🌐 Architecture Hybride Réelle - Smart Office 2.0

Ce document décrit l'architecture technique telle qu'elle est implémentée dans le dépôt, basée sur une hybridation entre le site local et une infrastructure IaaS/PaaS sur Azure.

## 📊 Schéma d'Architecture (Implémentation Réelle)

```mermaid
graph LR
    %% SITE LOCAL
    subgraph LOCAL ["🏢 SITE LOCAL (10.10.x.x)"]
        direction TB
        PFS["🛡️ PfSense"]
        SW["🖧 Cisco Switch"]
        
        subgraph VLANS ["VLANs"]
            V20["🖥️ Srv (AD, Zabbix)"]
            V40["📡 IoT (Capteurs)"]
            V30["👥 Users"]
        end
        
        PFS --- SW
        SW --- V20
        SW --- V40
        SW --- V30
    end

    %% TUNNEL
    PFS <== "🔗 VPN IPsec" ==> VGW

    %% AZURE CLOUD
    subgraph AZURE ["🟦 AZURE CLOUD (172.16.x.x)"]
        direction TB
        VGW["🌐 VPN Gateway"]
        
        subgraph COMPUTE ["Ressources"]
            direction LR
            DC_AZ["🏠 AD Replica"]
            DOCKER["🐳 Docker Host VM"]
        end
        
        subgraph CONTAINERS ["Containers (DOCKER)"]
            WEB["Web App"]
            DB["DB (PG/Mongo)"]
        end
        
        VGW --- COMPUTE
        DOCKER --- WEB
        WEB --- DB
    end

    %% FLUX TRANSVERSES
    V20 -. "Supervision" .-> DOCKER
    DC_AZ -. "Sync" .-> V20

    %% STYLING
    style LOCAL fill:#fff4dd,stroke:#d4a017
    style AZURE fill:#e1f5fe,stroke:#01579b
    style PFS fill:#f96
    style VGW fill:#f96
    style WEB fill:#69f
    style CONTAINERS fill:#f0f0f0,stroke-dasharray: 5 5
```

## 🔍 Détails de l'implémentation (Branche Develop)

### 1. Couche DevOps (Mehdi)
*   **Orchestration** : Utilisation de Docker Compose pour gérer la pile applicative sur un hôte Docker (VM Azure).
*   **Conteneurs** : 
    *   `smartoffice_web` : Application Node.js.
    *   `smartoffice_postgres` : Données structurées (PostgreSQL 15).
    *   `smartoffice_mongo` : Logs IoT (MongoDB 6).

### 2. Couche Réseau (Ilyes)
*   **Segmentation** : 4 VLANs distincts sur le site local pour isoler le trafic IoT et serveurs.
*   **Sécurité** : Firewall PfSense gérant le tunnel IPsec vers Azure.

### 3. Couche Système & Cloud (Océane)
*   **Hybridation AD** : Windows Server 2019 local et replica VM sur Azure pour assurer la continuité de service.

### 4. Couche Data & Supervision (Florian)
*   **Supervision** : Serveur Zabbix local monitorant les instances cloud et locales.
*   **Bases de données** : Maintenance et optimisation des instances PostgreSQL et MongoDB.
