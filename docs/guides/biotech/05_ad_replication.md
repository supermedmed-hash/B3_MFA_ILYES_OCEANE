# 🔄 Module 5 : Réplication AD
Étendre ton domaine Windows Server vers Azure via le tunnel VPN.

## 1. Configuration de la VM Azure
1.  Déployez une VM Windows Server 2019 dans le `Subnet-AD`.
2.  **DNS :** Dans les propriétés de la carte réseau Azure, fixez le DNS sur `10.10.10.10` (ton AD local).
3.  **Test :** Ouvre un PowerShell et tape `Test-ComputerSecureChannel` ou `ping biotech.corp`.

## 2. Rôle AD DS
1.  Sur la VM Azure, ouvrez le **Server Manager**.
2.  **Add Roles and Features > Active Directory Domain Services**.
3.  Une fois installé, cliquez sur le drapeau jaune : **Promote this server to a domain controller**.
4.  Option : **Add a domain controller to an existing domain**.
5.  Domaine : `biotech.corp`.
6.  Crédentials : `BIOTECH\Administrator`.

## 3. Vérification
Une fois redémarré, vérifiez la réplication avec :
`repadmin /showrepl`
