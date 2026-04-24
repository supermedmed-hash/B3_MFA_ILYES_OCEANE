# 🛡️ Module 2 : pfSense - VLANs & Firewalling
Configuration des interfaces virtuelles et des règles de sécurité Biotech sur pfSense.

## 1. Création des VLANs
Sur l'interface Web de pfSense :
1.  Allez dans **Interfaces > Assignments > VLANs**.
2.  **Parent Interface :** Choisissez l'interface reliée au switch (ex: `vtnet1` ou `em1`).
3.  Ajouter les Tags :
    *   VLAN 10 (Servers)
    *   VLAN 20 (Employees)
    *   VLAN 30 (R&D)
    *   VLAN 100 (Management)

## 2. Adressage IP
Assignez les IPs statiques suivantes aux interfaces créées dans **Interfaces > [Nom du VLAN]** :
*   **VLAN 10 :** 10.10.10.1/24
*   **VLAN 20 :** 10.10.20.1/23
*   **VLAN 30 :** 10.10.30.1/24

## 3. Firewalling (Matrix de Flux)
Dans **Firewall > Rules**, créez les règles critiques :

### Règle R&D (VLAN 30)
*   **Action :** Pass
*   **Protocol :** TCP
*   **Source :** VLAN 30 Subnet
*   **Destination :** 10.10.10.10 (Serveur AD/SQL)
*   **Port :** 1433, 445

### Règle Isolation
*   **Action :** Block
*   **Source :** VLAN 30 Subnet
*   **Destination :** VLAN 20 Subnet

N'oubliez pas d'autoriser le DNS (port 53) et le HTTP/S vers le WAN pour les mises à jour.
