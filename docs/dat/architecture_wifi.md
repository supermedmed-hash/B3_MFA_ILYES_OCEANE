# 📶 Architecture WLAN (Wi-Fi) — Smart Office 2.0
**Auteur :** Ilyes | **Statut :** Validé

Cette section documente l'architecture du réseau sans-fil de l'entreprise, indispensable pour le travail hybride et la mobilité des collaborateurs.

---

## 1. Topologie Matérielle

L'infrastructure Wi-Fi repose sur une architecture **centralisée** (Contrôleur WLAN) pour faciliter le roaming (itinérance) entre les étages et unifier les politiques de sécurité.

*   **Contrôleur WLAN (WLC)** : 1x Cisco WLC 2504 (ou équivalent Meraki) hébergé dans la baie serveur (Étage 1) sur le VLAN de Management (VLAN 100).
*   **Points d'Accès (Access Points - AP)** : 11x APs Cisco Aironet répartis sur les 4 étages.
*   **Alimentation** : Tous les APs sont alimentés en **PoE+ (Power over Ethernet - 802.3at)** par les switchs d'accès Cisco 2960. Pas d'alimentation secteur nécessaire.

---

## 2. Radios et Canaux (Planification RF)

Pour éviter les interférences (Overlap) entre les étages et offrir une haute densité :
*   **Bande 2.4 GHz (IoT/Legacy)** : Uniquement les canaux non-recouvrants 1, 6, 11 en alternance. Puissance d'émission réduite.
*   **Bande 5 GHz (Collaborateurs)** : Privilégiée. Utilisation de canaux larges (40 MHz) en DFS pour garantir des débits élevés aux PC portables.
*   **Band Steering** : Activé sur le WLC pour forcer les clients compatibles à utiliser la bande 5 GHz (plus rapide, moins saturée).

---

## 3. Configuration des SSIDs et Sécurité

Le contrôleur diffuse différents SSIDs mappés directement sur les VLANs filaires de l'entreprise.

| SSID (Nom du réseau) | Bande | Authentification | Chiffrement | VLAN assigné | Rôle |
|:---|:---:|:---|:---|:---:|:---|
| `Biotech-Corp` | 5 GHz | **WPA2-Enterprise** (802.1X via RADIUS AD) | AES | VLAN 20 (Employés) | Réseau principal sécurisé. L'utilisateur utilise ses identifiants Windows. |
| `Biotech-R&D` | 5 GHz | **WPA2-Enterprise** (Filtrage Groupe AD) | AES | VLAN 30 (R&D) | Réseau ultra-isolé. Seuls les membres du groupe AD "R&D" peuvent s'y connecter. |
| `Biotech-IoT` | 2.4 GHz | **WPA2-PSK** (Clé pré-partagée complexe) | AES | VLAN 50 (IoT) | Pour les capteurs de présence/température ne gérant pas le 802.1X. Caches (SSID masqué). |
| `Biotech-Guest` | 2.4 / 5 GHz | **Portail Captif** (Open) | None (Chiffré via HTTPS sur le Web) | VLAN 99 (Guest) | Réseau invité isolé (Accès Internet uniquement). Isolation client activée. |

### 3.1 Explication du 802.1X (WPA2-Enterprise)
Lorsqu'un employé se connecte à `Biotech-Corp` :
1. Son PC contacte l'AP.
2. L'AP relaie la requête (EAP) au serveur RADIUS (Hébergé sur le Windows Server AD local).
3. L'AD valide le couple *Nom d'utilisateur / Mot de passe*.
4. Si valide, l'AP autorise la connexion et place le trafic du client dans le **VLAN 20**.

Cette méthode garantit la traçabilité complète des connexions et empêche le vol de clés Wi-Fi partagées.
