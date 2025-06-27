#!/bin/bash
# scripts/backup-test.sh
# Ce script teste le cycle complet de sauvegarde et de restauration avec Velero.

TEST_NAMESPACE="velero-test"
BACKUP_NAME="test-backup-$(date +%s)"

echo "--- Début du test de sauvegarde et restauration Velero ---"

echo "1. Création du namespace de test '$TEST_NAMESPACE' et d'un NGINX de démo..."
kubectl create namespace $TEST_NAMESPACE
kubectl -n $TEST_NAMESPACE apply -f - <<END
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
END
sleep 10

echo "2. Lancement de la sauvegarde Velero : $BACKUP_NAME..."
velero backup create $BACKUP_NAME --include-namespaces $TEST_NAMESPACE --wait

echo "3. Simulation d'un sinistre : suppression du namespace '$TEST_NAMESPACE'..."
kubectl delete namespace $TEST_NAMESPACE --wait

if kubectl get ns $TEST_NAMESPACE > /dev/null 2>&1; then
  echo "Erreur : Le namespace de test n'a pas pu être supprimé."
  exit 1
fi
echo "Le namespace a été supprimé avec succès."

echo "4. Lancement de la restauration à partir de la sauvegarde '$BACKUP_NAME'..."
velero restore create --from-backup $BACKUP_NAME --wait

echo "5. Vérification de la restauration..."
sleep 15
POD_STATUS=$(kubectl get pods -n $TEST_NAMESPACE -l app=nginx -o 'jsonpath={..status.phase}')

if [ "$POD_STATUS" == "Running" ]; then
  echo "✅ Succès : Le pod NGINX est de nouveau en cours d'exécution."
  # Nettoyage
  velero backup delete $BACKUP_NAME --confirm
  kubectl delete namespace $TEST_NAMESPACE
else
  echo "❌ Échec : Le pod n'a pas été restauré correctement. Statut actuel : $POD_STATUS"
  exit 1
fi
