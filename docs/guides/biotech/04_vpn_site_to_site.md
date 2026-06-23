# 🔒 Module 4 : Site-to-Site VPN (IPsec)
Mise en place du tunnel sécurisé entre ton GNS3 (On-Prem) et Azure (Cloud).

## 1. Configuration pfSense (VPN > IPsec)
### Phase 1 (P1)
*   **Remote Gateway :** L'IP publique de la Gateway Azure.
*   **Key Exchange :** IKEv2.
*   **Encryption :** AES 256 bits.
*   **Hash :** SHA256.
*   **DH Group :** 14 (2048 bit).
*   **Pre-Shared Key :** `BiotechSecretVPN2024!`

### Phase 2 (P2)
*   **Local Network :** Network `10.10.0.0/16`.
*   **Remote Network :** Network `10.100.0.0/16`.
*   **Protocol :** ESP.

## 2. Configuration Azure
1.  **Local Network Gateway :**
    *   IP Address : Votre IP publique actuelle (celle de votre box).
    *   Address Space : `10.10.0.0/16`.
2.  **Connection :**
    *   Type : Site-to-site (IPsec).
    *   Virtual Network Gateway : Celle créée au Module 3.
    *   Local Network Gateway : Celle que vous venez de créer.
    *   Shared Key (PSK) : `BiotechSecretVPN2024!`
