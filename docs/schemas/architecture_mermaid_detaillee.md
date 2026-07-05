# 🌐 Architecture Hybride Réelle - Smart Office 2.0 (Mermaid Edition)

Ce document fournit la version Mermaid du schéma d'architecture finale, synchronisée avec l'implémentation de la branche `develop`.

## 📊 Diagramme Mermaid Détaillé

```mermaid
graph TB
    subgraph "🟦 MICROSOFT AZURE (VNet - 10.100.0.0/16)"
        subgraph "Identity Subnet"
            DC_AZ["SRV-AD-CLOUD\n(Azure VM - Replica)"]
        end

        subgraph "App & Data Subnet"
            subgraph "Docker Host (VM)"
                direction TB
                WEB["smartoffice_web\n(Node.js App)"]
                PG["smartoffice_postgres\n(PostgreSQL 15)"]
                MG["smartoffice_mongo\n(MongoDB 6)"]
                
                WEB --- PG
                WEB --- MG
            end
        end
        
        VGW["Azure VPN Gateway"]
    end

    subgraph "🏢 SITE LOCAL (On-Premise - 10.10.0.0/16)"
        PFS["Firewall PfSense\n(IPsec Gateway)"]
        
        subgraph "Segmentation VLANs"
            subgraph "VLAN 10 (Servers)"
                DC_LOC["SRV-AD-LOCAL\n(Windows Server)"]
                DKR["SRV-DOCKER\n(Docker Host)"]
            end
            
            V20["VLAN 20\n(Employees)"]
            V30["VLAN 30\n(R&D Isolé)"]
            
            subgraph "VLAN 50 (IoT)"
                IOT["Capteurs Salles\n(Da Vinci, Lovelace, Turing)"]
            end
            
            subgraph "VLAN 100 (Management)"
                ZBX["Zabbix Server\n(Florian)"]
            end
        end
    end

    %% Connexions Hybrides
    PFS <== "Tunnel IPsec VPN" ==> VGW
    VGW --- DC_AZ
    VGW --- WEB

    %% Flux Applicatifs & Monitoring
    DC_AZ <-. "Sync AD" .-> DC_LOC
    ZBX -. "Monitoring Agent" .-> WEB
    ZBX -. "SNMP" .-> PFS
    WEB -- "Collecte Data" --> IOT

    %% Styling
    style PFS fill:#f96,stroke:#333,stroke-width:2px
    style VGW fill:#f96,stroke:#333,stroke-width:2px
    style WEB fill:#69f,stroke:#333,stroke-width:2px
    style DC_AZ fill:#9f9,stroke:#333,stroke-width:2px
    style DC_LOC fill:#9f9,stroke:#333,stroke-width:2px
    style ZBX fill:#ff9,stroke:#333,stroke-width:2px
```

## 📝 Guide de Lecture
*   **Conteneurisation** : Les services Web, Postgres et Mongo sont regroupés dans une seule VM Docker sur Azure pour le PoC.
*   **Hybridation** : Le tunnel VPN permet la synchronisation des annuaires Active Directory entre le site local et Azure.
*   **Supervision** : Florian gère Zabbix depuis le VLAN 20 local pour monitorer l'ensemble de l'infrastructure.
