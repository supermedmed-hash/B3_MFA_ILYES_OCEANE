# 🛡️ Guide de Configuration pfSense - Smart Office 2.0

Ce guide détaille la configuration complète du firewall **pfSense** pour le projet Smart Office 2.0.

---

## Prérequis

- pfSense installé dans la VM VMware (`D:\VM\PfSense.vmx`)
- 2 interfaces réseau :
  - `em0` (VMware ethernet0) → **WAN** (DHCP via VMware NAT)
  - `em1` (VMware ethernet1) → **LAN** (Trunk 802.1Q vers SW-CORE-BIOTECH)
- Identifiants par défaut : `admin` / `pfsense`

---

## Étape 1 : Démarrage et assignation des interfaces (Console)

### 1.1 Démarrer pfSense dans GNS3
- Clic droit sur le nœud **pfSense-1** → **Start**
- Clic droit → **Console** (ouvrira la console VMware)

### 1.2 Assignation des interfaces
Au menu principal pfSense (option 1), configurez :

```
Should VLANs be set up now [y|n]? y

VLAN-capable interface: em1
VLAN tag: 10
VLAN-capable interface: em1
VLAN tag: 20
VLAN-capable interface: em1
VLAN tag: 30
VLAN-capable interface: em1
VLAN tag: 100

(press Enter when done)

Enter the WAN interface name: em0
Enter the LAN interface name: em1.10
Enter the Optional 1 interface name: em1.20
Enter the Optional 2 interface name: em1.30
Enter the Optional 3 interface name: em1.100

Do you want to proceed? y
```

### 1.3 Configuration des IPs (Option 2 du menu)

#### WAN (em0) - DHCP automatique
```
Interface: 1 (WAN)
Configure IPv4 via DHCP? y
Configure IPv6 via DHCP6? n
Revert to HTTP? n
```

#### LAN / VLAN 10 - SERVERS (em1.10)
```
Interface: 2 (LAN)
New LAN IPv4 address: 10.10.10.254
Subnet bit count: 24
Upstream gateway: (press Enter, none)
Configure IPv6? n
Enable DHCP server on LAN? n  (IPs statiques pour les serveurs)
Revert to HTTP? y  (pour accéder au WebGUI en HTTP)
```

#### OPT1 / VLAN 20 - EMPLOYEES (em1.20)
```
Interface: 3 (OPT1)
New OPT1 IPv4 address: 10.10.20.254
Subnet bit count: 24
Upstream gateway: (press Enter)
Configure IPv6? n
Enable DHCP server on OPT1? y
DHCP start address: 10.10.20.100
DHCP end address: 10.10.20.200
```

#### OPT2 / VLAN 30 - R&D (em1.30)
```
Interface: 4 (OPT2)
New OPT2 IPv4 address: 10.10.30.254
Subnet bit count: 24
Upstream gateway: (press Enter)
Configure IPv6? n
Enable DHCP server on OPT2? y
DHCP start address: 10.10.30.100
DHCP end address: 10.10.30.200
```

#### OPT3 / VLAN 100 - MANAGEMENT (em1.100)
```
Interface: 5 (OPT3)
New OPT3 IPv4 address: 10.10.100.254
Subnet bit count: 24
Upstream gateway: (press Enter)
Configure IPv6? n
Enable DHCP server on OPT3? n  (IPs statiques pour le management)
```

---

## Étape 2 : Configuration WebGUI

### 2.1 Accès au WebGUI
- Depuis un PC dans le VLAN 10 (ou via le navigateur de votre machine hôte si pfSense est accessible)
- URL : `http://10.10.10.254` ou `https://10.10.10.254`
- Login : `admin` / `pfsense`

### 2.2 Renommer les interfaces
Aller dans **Interfaces → Assignments** :

| Interface pfSense | Renommer en | Description |
|---|---|---|
| LAN (em1.10) | `SERVERS` | VLAN 10 - Serveurs |
| OPT1 (em1.20) | `EMPLOYEES` | VLAN 20 - Postes employés |
| OPT2 (em1.30) | `RD_ZONE` | VLAN 30 - Recherche & Développement |
| OPT3 (em1.100) | `MANAGEMENT` | VLAN 100 - Administration |

---

## Étape 3 : Règles de Firewall

### 3.1 Politique par défaut
- **WAN** : Bloquer tout (par défaut)
- **LAN/SERVERS** : Autoriser tout sortant
- **EMPLOYEES** : Autoriser vers SERVERS, bloquer vers R&D
- **RD_ZONE** : Autoriser UNIQUEMENT vers AD (SMB/SQL), bloquer le reste
- **MANAGEMENT** : Autoriser tout (admin)

### 3.2 Règles à créer

#### Interface SERVERS (VLAN 10)
| Action | Source | Destination | Port | Description |
|--------|--------|-------------|------|-------------|
| Pass | SERVERS net | any | * | Serveurs accès complet |

#### Interface EMPLOYEES (VLAN 20)
| Action | Source | Destination | Port | Description |
|--------|--------|-------------|------|-------------|
| **Block** | EMPLOYEES net | RD_ZONE net | * | Isolation R&D |
| Pass | EMPLOYEES net | SERVERS net | * | Accès aux serveurs |
| Pass | EMPLOYEES net | any | 80, 443 | Accès Internet |

#### Interface RD_ZONE (VLAN 30)
| Action | Source | Destination | Port | Description |
|--------|--------|-------------|------|-------------|
| **Block** | RD_ZONE net | EMPLOYEES net | * | Isolation Employés |
| Pass | RD_ZONE net | 10.10.10.10 | 445 | SMB vers AD uniquement |
| Pass | RD_ZONE net | 10.10.10.10 | 1433 | SQL vers AD uniquement |
| **Block** | RD_ZONE net | any | * | Bloquer tout le reste |

#### Interface MANAGEMENT (VLAN 100)
| Action | Source | Destination | Port | Description |
|--------|--------|-------------|------|-------------|
| Pass | MANAGEMENT net | any | * | Accès complet admin |

---

## Étape 4 : Configuration VPN IPsec (vers Azure)

### 4.1 Paramètres du tunnel

| Paramètre | Valeur |
|-----------|--------|
| Remote Gateway | `<IP_PUBLIQUE_AZURE_VPN_GATEWAY>` |
| IKE Version | IKEv2 |
| Authentication | Pre-Shared Key |
| Pre-Shared Key | `<GENEREE_PAR_SCRIPT_AZURE>` |
| My Identifier | My IP address |
| Peer Identifier | Peer IP address |

### 4.2 Phase 1 (IKE)

| Paramètre | Valeur |
|-----------|--------|
| Encryption Algorithm | AES 256 |
| Hash Algorithm | SHA256 |
| DH Group | 14 (2048 bit) |
| Lifetime | 28800 seconds |

### 4.3 Phase 2 (IPsec SA)

| Paramètre | Valeur |
|-----------|--------|
| Mode | Tunnel IPv4 |
| Local Network | `10.10.0.0/16` |
| Remote Network | `10.100.0.0/16` |
| Protocol | ESP |
| Encryption | AES 256 |
| Hash Algorithm | SHA256 |
| PFS Key Group | 14 (2048 bit) |
| Lifetime | 3600 seconds |

### 4.4 Firewall Rule pour IPsec
- **Interface** : IPsec
- **Action** : Pass
- **Source** : `10.100.0.0/16` (réseau Azure)
- **Destination** : `10.10.0.0/16` (réseau local)
- **Protocol** : any

---

## Étape 5 : Vérification

### Tests depuis la console pfSense (Option 7 - Shell)
```bash
# Vérifier les interfaces
ifconfig

# Vérifier les VLANs
ifconfig | grep vlan

# Tester la connectivité VLAN 10
ping -c 3 10.10.10.10

# Tester la connectivité VLAN 20
ping -c 3 10.10.20.50

# Vérifier le tunnel VPN
ipsec statusall
```

### Tests depuis les VPCS (console GNS3)
```
# Depuis PC-EMPLOYEE-1 (VLAN 20) :
ping 10.10.10.10    # → Doit fonctionner (vers SERVERS)
ping 10.10.30.50    # → Doit ÉCHOUER (isolation R&D)

# Depuis PC-RD-LAB1 (VLAN 30) :
ping 10.10.10.10    # → Doit fonctionner (vers AD)
ping 10.10.20.50    # → Doit ÉCHOUER (isolation Employees)
```
