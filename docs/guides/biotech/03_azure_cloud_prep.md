# ☁️ Module 3 : Azure Cloud Preparation
Préparation du réseau virtuel (VNet) dans Microsoft Azure.

## 1. Virtual Network (VNet)
Créez un nouveau VNet :
*   **Nom :** `VNET-BIOTECH-CLOUD`
*   **Région :** (Celle de votre choix, ex: West Europe)
*   **Espace d'adressage :** `10.100.0.0/16`

## 2. Subnets
Ajoutez les sous-réseaux suivants :
*   **Subnet-AD :** `10.100.1.0/24` (Pour la VM Replica)
*   **GatewaySubnet :** `10.100.255.0/27` (Nom obligatoire pour la passerelle VPN)

## 3. VPN Gateway
1.  Cherchez **Virtual Network Gateway** dans la barre de recherche Azure.
2.  **SKU :** `VpnGw1`.
3.  **Génération :** `Generation 1`.
4.  **VNet :** Sélectionnez `VNET-BIOTECH-CLOUD`.
5.  **Public IP :** Créez-en une nouvelle (ex: `pip-vpn-biotech`).

*⚠️ La création de la Gateway prend environ 25 minutes. Profitez-en pour configurer GNS3.*
