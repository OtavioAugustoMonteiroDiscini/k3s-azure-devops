#!/bin/bash

# Backup Automatizado de Recursos K8s
BACKUP_DIR="$HOME/k8s-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║       Backup K8s - Iniciando           ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"

mkdir -p $BACKUP_PATH

echo -e "${YELLOW}[1/5] Fazendo backup dos namespaces...${NC}"
for ns in $(kubectl get ns -o jsonpath='{.items[?(@.metadata.name!="kube-system")].metadata.name}'); do
    echo "  📦 Namespace: $ns"
    mkdir -p $BACKUP_PATH/$ns
    kubectl get all -n $ns -o yaml > $BACKUP_PATH/$ns/all-resources.yaml 2>/dev/null || true
done

echo -e "${YELLOW}[2/5] Backup de ConfigMaps...${NC}"
kubectl get configmaps --all-namespaces -o yaml > $BACKUP_PATH/configmaps.yaml

echo -e "${YELLOW}[3/5] Backup de Secrets...${NC}"
kubectl get secrets --all-namespaces -o yaml > $BACKUP_PATH/secrets.yaml

echo -e "${YELLOW}[4/5] Backup de PersistentVolumes...${NC}"
kubectl get pv -o yaml > $BACKUP_PATH/persistent-volumes.yaml 2>/dev/null || true

echo -e "${YELLOW}[5/5] Compactando backup...${NC}"
cd $BACKUP_DIR
tar -czf backup-$DATE.tar.gz $DATE/
rm -rf $DATE/

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Backup Concluído!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo -e "${GREEN}Arquivo: $BACKUP_DIR/backup-$DATE.tar.gz${NC}"
echo -e "${YELLOW}Tamanho: $(du -h $BACKUP_DIR/backup-$DATE.tar.gz | cut -f1)${NC}"
