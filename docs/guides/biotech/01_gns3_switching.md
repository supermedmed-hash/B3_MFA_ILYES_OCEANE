# 🛠️ Module 1 : GNS3 & Cisco Switching
Ce guide couvre la configuration du commutateur de cœur (Core Switch) dans GNS3 pour Biotech Corp.

## 1. Topologie de base
*   **Port Gi0/0 :** Connecté à pfSense (Interface LAN).
*   **Port Gi0/1 à 0/10 :** VLAN 10 (Serveurs).
*   **Port Gi0/11 à 0/20 :** VLAN 20 (Employés).

## 2. Configuration IOS
Connecte-toi en console sur ton switch Cisco dans GNS3 et tape ces commandes :

```bash
enable
conf t
hostname SW-CORE-BIOTECH

# Création des VLANs
vlan 10
 name SERVERS
vlan 20
 name EMPLOYEES
vlan 30
 name RD_BIOTECH
vlan 40
 name VOIP
vlan 50
 name IOT
vlan 100
 name MANAGEMENT
exit

# Config du TRUNK vers pfSense
interface GigabitEthernet0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 description LINK_TO_PFSENSE
 exit

# Config des ports d'accès pour les Serveurs (VLAN 10)
interface range GigabitEthernet0/1 - 10
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 exit

# Config des ports d'accès pour les Employés (VLAN 20)
interface range GigabitEthernet0/11 - 20
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
 exit

write memory
```

## 3. Vérification
Vérifie que tes VLANs sont bien créés avec la commande :
`show vlan brief`
