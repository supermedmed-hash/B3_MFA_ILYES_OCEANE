# 🧬 Plan d'Adressage IP & Segmentation - Biotech Corp
**Auteur :** Ilyes (Lead Réseau & Sécurité)
**Statut :** Validé - Prêt pour implémentation GNS3 / Azure

## 1. Plan d'Adressage IP (RFC 1918)
Le siège utilise le supernet `10.10.0.0/16`.

| Zone / VLAN | VLAN ID | Réseau | CIDR | Passerelle | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Servers & Infra** | 10 | 10.10.10.0 | /24 | 10.10.10.1 | AD, DNS, DHCP, Files |
| **Employees** | 20 | 10.10.20.0 | /23 | 10.10.20.1 | Postes de travail (510 IPs) |
| **R&D / Biotech** | 30 | 10.10.30.0 | /24 | 10.10.30.1 | Labos, Données sensibles |
| **VoIP** | 40 | 10.10.40.0 | /24 | 10.10.40.1 | Téléphonie IP |
| **IoT** | 50 | 10.10.50.0 | /24 | 10.10.50.1 | Imprimantes, Capteurs |
| **Guest** | 99 | 10.10.99.0 | /24 | 10.10.99.1 | Wi-Fi Invités (Isolé) |
| **Management** | 100 | 10.10.100.0| /24 | 10.10.100.1| Switchs, AP, Firewall |
| **VPN Clients** | 150 | 10.10.150.0| /24 | 10.10.150.1| Télétravail |
| **DMZ** | 200 | 10.10.200.0| /24 | 10.10.200.1| Serveurs publics |

## 2. Matrice de Flux (Sécurité Firewall)
*   **Default Policy :** DENY ALL
*   **Règle Critique :** Aucun accès de `EMPLOYEES` vers `R&D`.
*   **Accès Azure :** Le tunnel VPN autorisera `10.10.10.0/24` <-> `10.100.0.0/16` pour la réplication AD.
