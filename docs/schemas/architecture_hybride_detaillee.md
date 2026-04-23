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
            end

            subgraph "VLAN 40: IoT (10.10.40.0/24)"
                IOT["Capteurs & Terminaux\nSmart Office"]
            end

            subgraph "VLAN 30: Users (10.10.30.0/24)"
                PC["Postes Clients"]
            </div
        end
    end

    %% Interconnexions
    PFS <== "Tunnel IPsec (S2S VPN)" ==> VGW
    
    %% Flux Cloud
    VGW --- DC_AZ
    VGW --- AZ_APP
    AZ_APP --- AZ_PG
    DC_AZ <-. "Réplication AD" .-> DC_LOC

    %% Flux Locaux
    PFS --- DC_LOC
    PFS --- DKR
    PFS --- IOT
    PFS --- PC
    
    %% Accès App
    DKR --- IOT
    AZ_APP -. "API Access" .-> IOT

    %% Styling
    style PFS fill:#f96,stroke:#333
    style VGW fill:#f96,stroke:#333
    style DKR fill:#69f,stroke:#333
    style AZ_APP fill:#0078d4,stroke:#fff,color:#fff
    style AZ_PG fill:#0078d4,stroke:#fff,color:#fff
    style DC_AZ fill:#9f9,stroke:#333
    style DC_LOC fill:#9f9,stroke:#333
```

## 📋 Inventaire Technique

### 1. Infrastructure Azure (Cloud)
| Composant | Instance / Type | Rôle |
|-----------|-----------------|------|
| **VNet** | `VNet-SmartOffice` | Réseau virtuel principal (172.16.0.0/16) |
| **Subnet Identity** | `172.16.1.0/24` | Héberge le DC secondaire Azure |
| **Subnet App** | `172.16.2.0/24` | Héberge l'application de production (App Service) |
| **Subnet Data** | `172.16.3.0/24` | Héberge la base PostgreSQL managée |
| **VPN Gateway** | `VpnGw1` | Terminaison du tunnel IPsec vers le site local |

### 2. Infrastructure Locale (On-Premise)
| Composant | Instance / Type | Rôle |
|-----------|-----------------|------|
| **PfSense** | Firewall / Routeur | Gateway, VPN S2S, Filtrage inter-VLANs |
| **VLAN 20** | `10.10.20.0/24` | Infrastructure critique (AD local, Docker PoC) |
| **VLAN 30** | `10.10.30.0/24` | Réseau des utilisateurs administratifs |
| **VLAN 40** | `10.10.40.0/24` | Objets connectés (IoT) pour le Smart Office |

### 3. Connectivité Hybride
*   **Tunnel IPsec (Site-to-Site)** : Relie le PfSense local à l'Azure VPN Gateway. Permet aux capteurs locaux (VLAN 40) de remonter des données vers l'App Service Cloud, et assure la réplication Active Directory entre les deux sites.
*   **Split-DNS** : Résolution de noms unifiée entre le domaine local et les ressources Cloud.
