#!/bin/bash

# Script de Deploy Automatizado do Nginx no K3s
# Autor: Azure for Students - DevOps Guide

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
NAMESPACE="producao"
APP_NAME="nginx-deployment"
MANIFESTS_DIR="$HOME/k8s-manifests"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Deploy Automatizado - Nginx K3s     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Verificar se K3s está rodando
echo -e "${YELLOW}[1/6] Verificando K3s...${NC}"
if ! systemctl is-active --quiet k3s; then
    echo -e "${RED}❌ Erro: K3s não está rodando${NC}"
    echo -e "${YELLOW}Tentando iniciar K3s...${NC}"
    sudo systemctl start k3s
    sleep 5
fi
echo -e "${GREEN}✅ K3s está rodando${NC}"

# Criar namespace se não existir
echo -e "${YELLOW}[2/6] Verificando namespace...${NC}"
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo -e "${YELLOW}Criando namespace $NAMESPACE...${NC}"
    kubectl create namespace $NAMESPACE
fi
echo -e "${GREEN}✅ Namespace OK${NC}"

# Aplicar ConfigMap
echo -e "${YELLOW}[3/6] Aplicando ConfigMap...${NC}"
kubectl apply -f $MANIFESTS_DIR/nginx-configmap.yaml
echo -e "${GREEN}✅ ConfigMap aplicado${NC}"

# Aplicar deployment
echo -e "${YELLOW}[4/6] Aplicando Deployment...${NC}"
kubectl apply -f $MANIFESTS_DIR/nginx-deployment-custom.yaml
echo -e "${GREEN}✅ Deployment aplicado${NC}"

# Aplicar service
echo -e "${YELLOW}[5/6] Aplicando Service...${NC}"
kubectl apply -f $MANIFESTS_DIR/nginx-service.yaml
echo -e "${GREEN}✅ Service aplicado${NC}"

# Aguardar pods ficarem prontos
echo -e "${YELLOW}[6/6] Aguardando pods ficarem prontos...${NC}"
kubectl wait --for=condition=ready pod \
    -l app=nginx \
    -n $NAMESPACE \
    --timeout=120s

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Status do Deploy               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Verificar status
kubectl get deployments -n $NAMESPACE
echo ""
kubectl get pods -n $NAMESPACE -o wide
echo ""
kubectl get services -n $NAMESPACE

# Obter informações de acesso
NODEPORT=$(kubectl get service nginx-service -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')
PUBLIC_IP=$(curl -s ifconfig.me)

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Deploy Concluído com Sucesso! 🚀    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🌐 Acesso Externo:${NC}"
echo -e "   ${GREEN}http://$PUBLIC_IP:$NODEPORT${NC}"
echo ""
echo -e "${BLUE}🔍 Acesso Interno:${NC}"
echo -e "   ${GREEN}http://nginx-service.producao.svc.cluster.local${NC}"
echo ""
echo -e "${YELLOW}💡 Teste com: ${NC}curl http://localhost:$NODEPORT"
echo ""
