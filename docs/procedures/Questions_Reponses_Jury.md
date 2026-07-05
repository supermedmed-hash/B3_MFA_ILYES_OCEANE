# 🎓 Questions Potentielles du Jury & Réponses (Soutenance B3)

Ce document recense les questions classiques posées par les jurys d'architecture sur des projets de cette envergure, triées par domaine d'expertise pour que chacun puisse préparer sa partie.

---

## 🌐 1. Pour Ilyes (Réseau & Sécurité)

**Q1. Pourquoi avoir choisi IPsec (IKEv2) plutôt qu'OpenVPN ou WireGuard pour relier votre site local au Cloud Azure ?**
* **Réponse :** IPsec est le standard industriel incontesté pour les connexions "Site-to-Site" (réseau à réseau). Contrairement à OpenVPN, IPsec est géré nativement par la passerelle "Azure VPN Gateway" sans avoir besoin de déployer une machine virtuelle tierce. L'utilisation d'IKEv2 garantit une reconnexion très rapide (MOBIKE) et une excellente sécurité (AES-256).

**Q2. Vous parlez de "Zero-Trust" dans le DAT. Comment cela se traduit-il concrètement dans vos règles de pare-feu ?**
* **Réponse :** Nous n'accordons aucune confiance implicite, même en interne. Notre pfSense est configuré avec une règle de base "Deny All". Le réseau est micro-segmenté (VLAN R&D isolé, VLAN Guest, etc.). Par exemple, la R&D ne peut pas communiquer avec les Employés. Côté Azure, les bases de données (IaaS) ont un Network Security Group (NSG) qui n'accepte *que* le trafic provenant de l'IP du Web App.

**Q3. Votre Wi-Fi utilise le WPA2-Enterprise (802.1X) couplé à l'Active Directory. Que se passe-t-il si la liaison avec l'AD est coupée ?**
* **Réponse :** C'est un point critique (SPOF). Dans l'architecture cible du DAT, l'AD est hébergé en local, donc une coupure Internet ne coupe pas le Wi-Fi. Cependant, si le serveur AD tombe en panne, le serveur RADIUS ne peut plus valider les identifiants. Les utilisateurs déjà connectés gardent leur session (bail), mais les nouveaux ne pourront pas se connecter. La solution de production serait de déployer un contrôleur de domaine secondaire (Replica) pour la Haute Disponibilité.

---

## ☁️ 2. Pour Océane (Système & Cloud)

**Q1. Pourquoi avoir choisi du PaaS (Azure App Service) pour l'application Web, plutôt que de simples machines virtuelles (IaaS) ?**
* **Réponse :** Pour optimiser le TCO (Total Cost of Ownership) et l'agilité. Le PaaS nous libère du MCO (Maintien en Condition Opérationnelle) : nous n'avons pas d'OS Linux à patcher ou à sécuriser, Azure s'en occupe. De plus, l'App Service permet un "Auto-Scaling" (Scale-out) automatique : si l'entreprise grandit, Azure peut cloner le conteneur en quelques secondes pour absorber la charge, ce qui est très complexe à scripter sur des VMs classiques.

**Q2. Dans la maquette, vos serveurs (AD, Zabbix) sont finalement dans un IaaS Azure. Financièrement, pourquoi ne pas avoir tout mis en PaaS/SaaS ou 100% Cloud Entra ID ?**
* **Réponse :** Dans notre architecture idéale, le choix technique que nous aurions fait pour l'Active Directory aurait été d'avoir un contrôleur de domaine physique On-Premise, directement répliqué vers un contrôleur secondaire dans Azure (IaaS) via le tunnel IPsec pour une haute disponibilité (ou synchronisé via Azure AD Connect). Cependant, par manque de budget et en raison des quotas de notre abonnement étudiant, nous avons dû simuler cet environnement On-Premise directement dans l'IaaS. Ce choix théorique répondait à une vraie problématique d'entreprise : garder la souveraineté de l'identité et l'héritage technique (GPO locales), tout en préparant une transition en douceur vers Entra ID.

---

## 📊 3. Pour Florian (Supervision & Observabilité)

**Q1. Pourquoi utiliser deux outils (Zabbix ET Grafana) ? Zabbix ne fait-il pas déjà des tableaux de bord ?**
* **Réponse :** Ils ont des rôles complémentaires. Zabbix est le moteur "backend" extrêmement puissant pour la collecte de métriques (SNMP, Agents), la gestion des déclencheurs complexes (Triggers) et l'alerting. Grafana est l'outil "frontend" : il excelle dans la data-visualisation. Grafana permet de créer des dashboards beaucoup plus ergonomiques, dynamiques et lisibles pour des personnes non-techniques (ex: direction, affichage sur écran dans l'open-space), en lisant directement dans la base de données de Zabbix via un plugin.

**Q2. Comment Zabbix arrive-t-il à monitorer des ressources situées dans le Cloud Azure depuis son réseau local ?**
* **Réponse :** Tout passe de manière sécurisée par le tunnel VPN IPsec. Zabbix (VLAN 100) interroge les ressources Azure via leurs IP privées. Pour les éléments PaaS qui n'ont pas d'IP privées fixes sans configuration coûteuse, nous pouvons utiliser l'API Azure Monitor (Service Principal) connectée à Zabbix pour remonter les métriques Cloud.

---

## 💻 4. Pour Mehdi (DevOps & Data)

**Q1. Pourquoi avez-vous complexifié l'architecture avec deux bases de données (PostgreSQL et MongoDB) au lieu de tout mettre dans une seule ?**
* **Réponse :** C'est le principe de la persistance polyglotte (Polyglot Persistence). Chaque technologie répond à un besoin spécifique. PostgreSQL (Relationnel, ACID) est parfait pour l'intégrité métier : il assure qu'une salle ne peut pas être réservée deux fois à la même heure. En revanche, MongoDB (NoSQL, orienté document) est idéal pour ingérer l'énorme volume des logs générés par les capteurs IoT (haute fréquence). Si un capteur s'emballe et génère 1000 requêtes/seconde, MongoDB encaisse la charge sans ralentir PostgreSQL, protégeant ainsi l'application de réservation métier.

**Q2. Vous parlez de pipeline CI/CD et de PRA. Que se passe-t-il si je supprime par erreur le Resource Group de l'application Web sur Azure ? En combien de temps repartez-vous (RTO) ?**
* **Réponse :** Notre RTO (Recovery Time Objective) sur l'applicatif web est de moins de 5 minutes. Grâce à notre approche Infrastructure as Code (script Azure CLI) et DevOps (GitHub Actions), nous ne configurons rien à la main. L'exécution de notre script maître recrée l'Azure Container Registry et l'App Service, puis GitHub Actions repousse automatiquement la dernière image Docker valide. L'application est alors de retour en ligne instantanément car elle est "Stateless" (sans état), les données étant sécurisées sur nos bases On-Premise.
