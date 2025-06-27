# Pipeline de Reprise d'Activité Multi-Cloud Automatisé

## Problème Résolu
Les entreprises subissent des risques de temps d'arrêt et de perte de données en raison de stratégies de reprise après sinistre (DR) inadéquates, en particulier dans des environnements multi-cloud. Ce projet s'attaque à ce défi en assurant une haute disponibilité sur AWS, Azure et GCP de manière rentable.

## Description du Projet
Ce projet met en œuvre un pipeline de reprise après sinistre entièrement automatisé pour une configuration multi-cloud (AWS, Azure, GCP) utilisant Kubernetes, Terraform et Velero. Il démontre une expertise en DevOps, GitOps et en gestion de la continuité d'activité.

### Tech Stack
- **IaC:** Terraform
- **Orchestration:** Kubernetes (EKS, AKS, GKE)
- **Sauvegarde/Restauration:** Velero
- **GitOps:** ArgoCD
- **Monitoring:** Prometheus, Grafana
- **CI/CD:** GitHub Actions
- **Tests de Chaos:** Chaos Monkey
- **Stockage:** AWS S3, Azure Blob Storage, Google Cloud Storage

### Structure des Dossiers
\`\`\`
disaster-recovery-pipeline/
├── terraform/
│   ├── eks.tf
│   ├── aks.tf
│   ├── gke.tf
│   └── variables.tf
├── kubernetes/
│   ├── velero-deployment.yaml
│   ├── argocd-configs/
│   │   └── sample-app.yaml
│   └── monitoring/
│       ├── prometheus.yaml
│       └── grafana.yaml
├── scripts/
│   ├── chaos-monkey.sh
│   └── backup-test.sh
├── .github/workflows/
│   └── ci-cd.yml
└── README.md
\`\`\`

### Prérequis
- Comptes AWS, Azure et GCP.
- Outils CLI installés : \`terraform\`, \`kubectl\`, \`aws\`, \`az\`, \`gcloud\`.
- Clés d'accès configurées pour chaque fournisseur cloud.

### Guide d'Installation
1.  **Cloner le dépôt**
    \`\`\`bash
    git clone <URL_DU_DEPOT>
    cd disaster-recovery-pipeline
    \`\`\`
2.  **Configurer les variables Terraform**
    - Remplissez le fichier \`terraform/variables.tf\` avec vos propres valeurs (noms de projet, régions, etc.).
    - Configurez vos identifiants cloud dans votre environnement.

3.  **Déployer l'Infrastructure**
    \`\`\`bash
    cd terraform
    terraform init
    terraform plan
    terraform apply --auto-approve
    \`\`\`
    Cette commande provisionnera les clusters EKS, AKS et GKE, ainsi que les buckets de stockage pour Velero.

4.  **Configurer \`kubectl\`**
    - Suivez les instructions affichées par Terraform en sortie pour configurer \`kubectl\` afin de communiquer avec vos nouveaux clusters.

5.  **Déployer les Outils Kubernetes**
    - Appliquez les manifestes pour Velero, ArgoCD, et le monitoring sur chaque cluster.
    \`\`\`bash
    # Pour chaque cluster
    kubectl config use-context <CONTEXT_DU_CLUSTER>
    kubectl apply -f ../kubernetes/velero-deployment.yaml
    kubectl apply -f ../kubernetes/monitoring/
    kubectl apply -f ../kubernetes/argocd-configs/
    \`\`\`

### Procédure de Basculement (Failover)
En cas de défaillance d'un cluster primaire (ex: EKS) :
1.  **Détection:** Prometheus/Grafana alertent sur la non-disponibilité du cluster.
2.  **Restauration:** Sur un cluster de secours (ex: GKE), utilisez Velero pour restaurer l'état le plus récent à partir des sauvegardes.
    \`\`\`bash
    velero restore create --from-backup <NOM_DE_LA_SAUVEGARDE>
    \`\`\`
3.  **Redirection du trafic:** Mettez à jour vos enregistrements DNS pour pointer vers l'ingress du cluster de secours.
4.  **Synchronisation GitOps:** ArgoCD s'assurera que toutes les applications sont déployées et configurées comme défini dans le dépôt Git.

### Objectifs de Reprise (RTO/RPO)
- **Objectif de Temps de Reprise (RTO - Recovery Time Objective):** Le temps maximal admissible pour restaurer le service après un sinistre. Mesuré par Grafana. $RTO_{mesuré} = T_{restauration} - T_{incident}$.
- **Objectif de Point de Reprise (RPO - Recovery Point Objective):** La perte de données maximale admissible. Déterminé par la fréquence des sauvegardes Velero (ex: toutes les heures). $RPO = 1$ heure.
