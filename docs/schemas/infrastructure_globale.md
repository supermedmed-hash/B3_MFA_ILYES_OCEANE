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
            V10["🖥️ Srv (AD, BDD, Zabbix)"]
            V20["👥 Employés"]
            V40["📡 IoT & VoIP"]
            V99["🛜 Guest"]
        end
        
        PFS --- SW
        SW --- V10
        SW --- V20
        SW --- V40
        SW --- V99
    end

    %% TUNNEL
    PFS <== "🔗 VPN IPsec" ==> VGW

    %% AZURE CLOUD
    subgraph AZURE ["🟦 AZURE CLOUD (172.16.x.x)"]
        direction TB
        VGW["🌐 VPN Gateway"]
        
        subgraph COMPUTE ["Ressources Managées"]
            direction LR
            ACR["📦 Azure Container Registry"]
            APPSVC["🌐 Azure App Service"]
        end
        
        subgraph CONTAINERS ["Containers App Service"]
            WEB["Web App Node.js"]
        end
        
        VGW --- APPSVC
        ACR -. "Pull Image" .-> APPSVC
        APPSVC --- WEB
    end

    %% FLUX TRANSVERSES
    V10 -. "Supervision (Zabbix)" .-> APPSVC
    WEB -. "Requêtes BDD" .-> V10

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
*   **Segmentation** : 8 VLANs distincts (Serveurs, Employés, R&D, VoIP, IoT, Management, Guest).
*   **Sécurité** : Firewall PfSense (Deny All) gérant le tunnel IPsec vers Azure et NAC (802.1X).

### 3. Couche Système & Cloud (Océane)
*   **Identité** : Active Directory local (Windows Server 2019) gérant l'authentification réseau.
*   **Choix Cloud** : PaaS Azure (App Service) privilégié (TCO réduit de 74%) par rapport à l'IaaS pur.

### 4. Couche Data & Supervision (Florian)
*   **Supervision** : Serveur Zabbix local monitorant les instances cloud et locales.
*   **Bases de données** : Maintenance et optimisation des instances PostgreSQL et MongoDB.
