# 🔀 Matrice des Flux Réseau — Smart Office 2.0
**Auteur :** Ilyes (Lead Réseau) | **Statut :** Validé
**Contexte :** Implémentation du pare-feu pfSense en politique "Deny All" par défaut.

Cette matrice documente l'ensemble des flux autorisés (ACLs) entre les différents sous-réseaux (VLANs) et les environnements extérieurs (Internet, Cloud Azure). 
**Tout flux non explicitement autorisé dans ce tableau est bloqué par défaut.**

---

## 1. Plan d'Adressage (Rappel)

| Zone | Sous-réseau | Description |
|:---|:---|:---|
| **VLAN 10** | `10.10.10.0/24` | Serveurs & Administration |
| **VLAN 20** | `10.10.20.0/24` | Employés (Data) |
| **VLAN 30** | `10.10.30.0/24` | R&D (Isolé) |
| **VLAN 40** | `10.10.40.0/24` | Téléphonie IP (VoIP) |
| **VLAN 50** | `10.10.50.0/24` | IoT & Imprimantes |
| **VLAN 99** | `10.10.99.0/24` | Guest (Wi-Fi public) |
| **VLAN 100** | `10.10.100.0/24` | Management Réseau (Zabbix, AP) |
| **Azure VNet** | `10.100.0.0/16` | Ressources Cloud Azure |

---

## 2. Matrice des Flux Autorisés (ACLs pfSense)

*Légende :* ✅ Autorisé | ❌ Bloqué par défaut

| ID | Source | Destination | Port / Protocole | Action | Description / Justification |
|:---|:---|:---|:---|:---:|:---|
| **DNS-01** | Tous les VLANs locaux | VLAN 10 (`10.10.10.10` - AD) | 53 (UDP/TCP) | ✅ | Résolution DNS locale vers le contrôleur de domaine |
| **DNS-02** | VLAN 10 (`10.10.10.10` - AD) | Internet (Ex: `8.8.8.8`) | 53 (UDP) | ✅ | Forwarding DNS pour les requêtes externes |
| **AD-01** | VLAN 20, VLAN 30 | VLAN 10 (`10.10.10.10` - AD) | 88, 389, 445, 636, 3268 (TCP/UDP) | ✅ | Authentification Kerberos, LDAP, SMB (GPO) pour les postes clients |
| **WEB-01** | VLAN 20, VLAN 30 | Internet | 80, 443 (TCP) | ✅ | Navigation Web standard pour les employés et R&D |
| **WEB-02** | VLAN 99 (Guest) | Internet | 80, 443 (TCP) | ✅ | Accès Internet uniquement pour les invités (Isolé du LAN) |
| **APP-01** | Tous les VLANs locaux | Azure App Service | 443 (TCP) | ✅ | Accès à l'application web Smart Office (HTTPS) |
| **DB-01** | Azure VNet (App Web) | VLAN 10 (`10.10.10.20` - SRV-DOCKER) | 5432 (TCP) | ✅ | L'application cloud accède à PostgreSQL via le tunnel VPN |
| **DB-02** | Azure VNet (App Web) | VLAN 10 (`10.10.10.20` - SRV-DOCKER) | 27017 (TCP) | ✅ | L'application cloud pousse les logs IoT vers MongoDB via VPN |
| **IOT-01** | VLAN 50 (Capteurs) | VLAN 10 (`10.10.10.20` - SRV-DOCKER) | 27017 (TCP) | ✅ | Envoi direct de données MQTT/Mongo par les capteurs internes |
| **MGT-01** | VLAN 10, VLAN 20 | VLAN 100 (`10.10.100.10` - Zabbix) | 80, 443 (TCP) | ✅ | Accès au dashboard Grafana/Zabbix par les admins |
| **ZBX-01** | VLAN 100 (`10.10.100.10`) | Tous les VLANs locaux | 10050 (TCP), ICMP | ✅ | Collecte des métriques Zabbix Agent et ping |
| **ZBX-02** | VLAN 100 (`10.10.100.10`) | Azure VNet (VMs) | 10050 (TCP), ICMP | ✅ | Collecte des métriques Cloud via le tunnel VPN |
| **VOIP-01** | VLAN 40 (Téléphones) | Internet (SIP Trunk FAI) | 5060, 10000-20000 (UDP) | ✅ | Flux SIP et RTP pour la téléphonie externe |
| **VPN-01** | pfSense (WAN) | Azure VPN Gateway (IP Pub) | 500, 4500 (UDP), ESP | ✅ | Établissement et maintien du tunnel VPN IPsec (IKEv2) |
| **BKP-01** | VLAN 10 (`10.10.10.20`) | VLAN 10 (`10.10.10.30` - NAS) | 445, 2049, 873 (TCP) | ✅ | Dépôt des sauvegardes BDD (SMB/NFS/Rsync) sur le NAS local |
| **BKP-02** | VLAN 10 (`10.10.10.30` - NAS) | Internet (Azure Blob) | 443 (TCP) | ✅ | Externalisation des sauvegardes vers le Cloud Azure |
| **ISOL-01**| VLAN 99 (Guest) | LAN (`10.10.0.0/16`) | Tous (Any) | ❌ | Blocage strict des invités vers les réseaux internes |
| **ISOL-02**| VLAN 30 (R&D) | VLAN 20 (Employés) | Tous (Any) | ❌ | Isolement du trafic R&D par rapport au reste de l'entreprise |

---

## 3. Paramètres Avancés pfSense

### 3.1 NAT (Network Address Translation)
- **Outbound NAT** : Activé en mode "Hybrid".
- Translation (PAT) configurée pour les réseaux `10.10.20.0/24` (Employés), `10.10.30.0/24` (R&D), `10.10.40.0/24` (VoIP) et `10.10.99.0/24` (Guest) vers l'IP publique WAN du pfSense pour l'accès Internet.
- **PAS de NAT** entre les réseaux locaux (VLAN 10 à 100) et le réseau Azure (`10.100.0.0/16`) car le tunnel IPsec gère le routage réseau-à-réseau pur (Phase 2 configurée sur ces subnets).

### 3.2 Filtrage applicatif (Layer 7)
- Utilisation de pfBlockerNG (optionnel) envisagée pour la phase de production pour bloquer les IP malveillantes connues et le trafic publicitaire/P2P sur le VLAN 99 (Guest).

---
*Fin du document.*
