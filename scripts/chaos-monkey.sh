#!/bin/bash
# scripts/chaos-monkey.sh
# Ce script simule une défaillance en supprimant un pod au hasard dans un namespace.

NAMESPACE="production"
echo "--- Chaos Monkey est à l'œuvre dans le namespace : $NAMESPACE ---"

POD_TO_DELETE=$(kubectl get pods -n $NAMESPACE -l app --field-selector=status.phase=Running -o jsonpath='{.items[?(@.metadata.ownerReferences[0].kind=="ReplicaSet")].metadata.name}' | tr ' ' '\n' | shuf -n 1)

if [ -z "$POD_TO_DELETE" ]; then
  echo "Aucun pod d'application trouvé à supprimer dans le namespace $NAMESPACE."
  exit 1
fi

echo "Cible sélectionnée pour la suppression : $POD_TO_DELETE"
kubectl delete pod $POD_TO_DELETE -n $NAMESPACE
echo "Pod $POD_TO_DELETE supprimé. Kubernetes devrait en créer un nouveau."
echo "--- Fin de l'opération Chaos Monkey ---"
