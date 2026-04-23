# ☁️ Schéma d'Infrastructure Cloud-First - Smart Office 2.0

Ce document présente l'architecture modernisée du projet, où le Système d'Information (SI) est centralisé sur **Microsoft Azure**, offrant scalabilité, haute disponibilité et sécurité native.

## 📊 Diagramme d'Architecture Cloud

```mermaid
graph TB
    subgraph "🟦 Microsoft Azure (Région France Central)"
        subgraph "🔒 Virtual Network (VNet)"
            
            subgraph "Identity Subnet"
                AAD["Azure AD / Entra ID"]
                WDS["Windows Server VM\n(Domain Controller)"]
            end

            subgraph "App Subnet"
                WEB["Azure App Service\n(Node.js Container)"]
            end

            subgraph "Data Subnet (Private Link)"
                PG["Azure DB for PostgreSQL\n(Flexible Server)"]
                MG["Azure Cosmos DB\n(API MongoDB)"]
            end

            subgraph "Management & Monitoring"
                AZM["Azure Monitor /\nLog Analytics"]
                ZBX["Zabbix Server (VM)"]
            end

            subgraph "Network Edge"
                AGW["Application Gateway\n(WAF & Load Balancer)"]
                VGW["VPN Gateway"]
            end
        end
    end

    subgraph "🏢 Site Local (Branch Office)"
        PFS["PfSense (Local Gateway)"]
        SW["Switch Cisco"]
        USR["Utilisateurs / IoT"]
    end

    subgraph "🏠 Utilisateurs Distants"
        WVD["Azure Virtual Desktop /\nVPN Point-to-Site"]
    end

    %% Connexions Cloud
    AGW ==> WEB
    WEB --> PG
    WEB --> MG
    AAD --- WEB
    AAD --- WDS
    
    %% Connexions Hybrides
    VGW <== "S2S VPN (IPsec)" ==> PFS
    VGW <== "P2S VPN" ==> WVD
    
    PFS --- SW
    SW --- USR

    %% Monitoring
    AZM -. "Metrics & Logs" .-> WEB
    AZM -. "Metrics & Logs" .-> PG
    ZBX -. "Agent Monitoring" .-> WDS

    %% Styling
    style AGW fill:#0078d4,stroke:#fff,color:#fff
    style WEB fill:#0078d4,stroke:#fff,color:#fff
    style PG fill:#0078d4,stroke:#fff,color:#fff
    style MG fill:#0078d4,stroke:#fff,color:#fff
    style AAD fill:#0078d4,stroke:#fff,color:#fff
    style VGW fill:#f96,stroke:#333
    style PFS fill:#f96,stroke:#333
```

## 🔍 Migration vers le SI Cloud

### 1. Couche Applicative (PaaS)
*   **Azure App Service** : L'application Node.js ne tourne plus sur un serveur local mais sur un service managé (PaaS). Cela permet l'auto-scaling et simplifie les mises à jour via GitHub Actions.
*   **Application Gateway (WAF)** : Protection contre les attaques web (OWASP Top 10) et répartition de charge.

### 2. Services de Données (Managed DB)
*   **PostgreSQL Flexible Server** : Base relationnelle managée avec sauvegardes automatiques et haute disponibilité.
*   **Cosmos DB (Mongo API)** : Stockage des logs IoT avec une latence ultra-faible et une distribution mondiale si nécessaire.

### 3. Identité et Sécurité
*   **Azure AD (Entra ID)** : Devient la source de vérité principale pour l'authentification.
*   **Identity Isolation** : Le contrôleur de domaine (VM) est sécurisé dans un subnet dédié pour les besoins legacy de l'AD classique.

### 4. Connectivité Hybride
*   **VPN Gateway** : Assure la liaison entre les ressources Cloud et les terminaux IoT ou utilisateurs restés sur le site physique (VLANs locaux via PfSense).

### 5. Supervision Native
*   **Azure Monitor** : Centralise tous les logs de la plateforme Azure pour une visibilité 360°.
