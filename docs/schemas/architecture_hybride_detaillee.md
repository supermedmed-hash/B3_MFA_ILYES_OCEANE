# 🌐 Architecture Hybride Détaillée - Smart Office 2.0

Ce schéma présente l'interconnexion entre l'infrastructure locale (On-Premise) et le Cloud Azure, avec un focus sur la segmentation réseau (VLANs/Subnets) et le placement des instances.

## 📊 Schéma des Réseaux et Instances

```mermaid
graph TD
    subgraph "🟦 CLOUD AZURE (VNet - 172.16.0.0/16)"
        subgraph "Identity Subnet (172.16.1.0/24)"
            DC_AZ["VM: DC-CLOUD\n(Replica AD)"]
        end

        subgraph "App Subnet (172.16.2.0/24)"
            AZ_APP["Azure App Service\n(Node.js App)"]
        end

        subgraph "Data Subnet (172.16.3.0/24)"
            AZ_PG["Azure DB PostgreSQL\n(Managed)"]
        end

        VGW["Azure VPN Gateway"]
    end

    subgraph "🏢 SITE LOCAL (10.10.0.0/16)"
        subgraph "🛡️ Firewall & Gateway"
            PFS["PfSense Firewall"]
        end

        subgraph "🖧 Segmentation VLANs"
            subgraph "VLAN 20: Serveurs (10.10.20.0/24)"
                DC_LOC["SRV-AD-LOCAL\n(Windows Server)"]
                DKR["Docker Host\n(PoC Application)"]
            SW["Switch Core"]
        end

        subgraph VLANS ["VLANs"]
            V10["🖥️ Srv (AD, DBs, Zabbix) - VLAN 10"]
            V20["👥 Employés - VLAN 20"]
            V30["🧪 R&D Isolé - VLAN 30"]
            V40["📞 VoIP - VLAN 40"]
            V50["📡 IoT - VLAN 50"]
            V99["🛜 Guest Wi-Fi - VLAN 99"]
            V100["🔧 Management - VLAN 100"]
        end
    end

    %% Interconnexions
    PFS <== "Tunnel IPsec (S2S VPN)" ==> VGW
    
    PFS --- SW
    SW --- V10
    SW --- V20
    SW --- V30
    SW --- V40
    SW --- V50
    SW --- V99
    SW --- V100
    
    %% Flux Cloud
    VGW --- DC_AZ
    VGW --- AZ_APP
    AZ_APP --- AZ_PG
    DC_AZ <-. "Réplication AD" .-> V10

    %% FLUX TRANSVERSES
    V100 -. "Supervision" .-> V10
    AZ_APP -. "Requêtes BDD" .-> V10

    %% Styling
    style PFS fill:#f96,stroke:#333
    style VGW fill:#f96,stroke:#333
    style AZ_APP fill:#0078d4,stroke:#fff,color:#fff
    style AZ_PG fill:#0078d4,stroke:#fff,color:#fff
    style DC_AZ fill:#9f9,stroke:#333
```

## 📋 Inventaire Technique

### 1. Documentation Applicative et Données
*   **Bases de données polyglottes** : [Modèle de données UML/Merise](../schemas/modele_donnees_UML.md) justifiant Postgres (relationnel) + Mongo (Time-Series).
*   **Stratégie de stockage et sauvegarde** : NAS en local avec réplication, script automatisé, Règle du 3-2-1. Voir [Stratégie de Stockage](strategie_stockage.md).

### 2. Couche Réseau et Sécurité (Ilyes)
*   **Plan d'adressage** : Plan IPv4 avec 8 VLANs isolés. Voir [Plan d'Adressage](../procedures/plan_adressage_biotech.md).
*   **Architecture Physique** : Bâtiment de 4 étages avec backbone fibre 10G. Voir [Schéma Physique](../schemas/schema_physique.md).
*   **Flux et ACLs** : Politique Deny All sur pfSense, matrice de flux validée. Voir [Matrice des Flux Réseau](../schemas/matrice_flux_reseau.md).
*   **Réseau Sans Fil (WLAN)** : Architecture centralisée avec WLC, SSID par VLAN, sécurité 802.1X. Voir [Architecture Wi-Fi](architecture_wifi.md).
*   **Politique de Sécurité (PSSI)** : Zero Trust, NAC, IAM. Voir [Politique de Sécurité](../procedures/politique_securite.html).

### 3. Couche Système & Cloud (Océane)
*   **Hybridation Active Directory** : GPO et contrôle d'accès local sur Windows Server 2019.
*   **Choix du Cloud** : Azure App Service + ACR, justifié par une analyse complète (TCO). Voir [Analyse Comparative Cloud](analyse_comparative_cloud.md).
*   **VPN IPSec** : Tunnel sécurisé IKEv2 entre pfSense et Azure VPN Gateway. Résolution de noms unifiée via Split-DNS entre le domaine local et les ressources Cloud.
