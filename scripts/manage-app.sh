#!/bin/bash

# Script de Gerenciamento de Aplicações K8s
set -e

NAMESPACE="producao"
APP_NAME="nginx-deployment"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function show_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Gerenciamento K8s - Menu Principal  ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Ver status da aplicacao"
    echo -e "${GREEN}2)${NC} Escalar aplicacao"
    echo -e "${GREEN}3)${NC} Fazer rollback"
    echo -e "${GREEN}4)${NC} Ver logs em tempo real"
    echo -e "${GREEN}5)${NC} Reiniciar pods"
    echo -e "${GREEN}6)${NC} Testar conectividade"
    echo -e "${GREEN}7)${NC} Atualizar imagem"
    echo -e "${GREEN}8)${NC} Deletar aplicacao"
    echo -e "${GREEN}0)${NC} Sair"
    echo ""
    read -p "$(echo -e ${YELLOW}Escolha uma opcao: ${NC})" choice
    
    case $choice in
        1) status ;;
        2) scale ;;
        3) rollback ;;
        4) logs ;;
        5) restart ;;
        6) test_connectivity ;;
        7) update_image ;;
        8) delete ;;
        0) exit 0 ;;
        *) echo -e "${RED}Opcao invalida${NC}"; sleep 2 ;;
    esac
}

function status() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}      Status da Aplicacao              ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Deployments:${NC}"
    kubectl get deployments -n $NAMESPACE
    echo ""
    
    echo -e "${YELLOW}Pods:${NC}"
    kubectl get pods -n $NAMESPACE -o wide
    echo ""
    
    echo -e "${YELLOW}Services:${NC}"
    kubectl get services -n $NAMESPACE
    echo ""
    
    echo -e "${YELLOW}Recursos:${NC}"
    kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics-server nao instalado"
    echo ""
    
    read -p "Pressione ENTER para continuar..."
}

function scale() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        Escalar Aplicacao              ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    CURRENT=$(kubectl get deployment $APP_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}')
    echo -e "${YELLOW}Replicas atuais: ${GREEN}$CURRENT${NC}"
    echo ""
    
    read -p "Numero de replicas desejado: " replicas
    
    if [[ ! "$replicas" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Numero invalido${NC}"
        sleep 2
        return
    fi
    
    echo -e "${YELLOW}Escalando para $replicas replicas...${NC}"
    kubectl scale deployment $APP_NAME --replicas=$replicas -n $NAMESPACE
    
    echo -e "${YELLOW}Aguardando rollout...${NC}"
    kubectl rollout status deployment/$APP_NAME -n $NAMESPACE
    
    echo -e "${GREEN}Escalado com sucesso!${NC}"
    sleep 2
}

function rollback() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}           Rollback                    ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Historico de Revisoes:${NC}"
    kubectl rollout history deployment/$APP_NAME -n $NAMESPACE
    echo ""
    
    read -p "Reverter para qual revisao? (deixe vazio para anterior): " revision
    
    if [ -z "$revision" ]; then
        kubectl rollout undo deployment/$APP_NAME -n $NAMESPACE
    else
        kubectl rollout undo deployment/$APP_NAME --to-revision=$revision -n $NAMESPACE
    fi
    
    echo -e "${YELLOW}Aguardando rollout...${NC}"
    kubectl rollout status deployment/$APP_NAME -n $NAMESPACE
    
    echo -e "${GREEN}Rollback concluido!${NC}"
    sleep 2
}

function logs() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}         Logs em Tempo Real            ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Listar pods
    mapfile -t PODS < <(kubectl get pods -n $NAMESPACE -l app=nginx -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n')
    
    if [ ${#PODS[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum pod encontrado${NC}"
        sleep 2
        return
    fi
    
    echo -e "${YELLOW}Pods disponiveis:${NC}"
    for i in "${!PODS[@]}"; do
        echo "$((i+1))) ${PODS[$i]}"
    done
    echo ""
    
    read -p "Escolha o pod (numero): " choice
    
    POD_INDEX=$((choice-1))
    if [ $POD_INDEX -ge 0 ] && [ $POD_INDEX -lt ${#PODS[@]} ]; then
        echo -e "${YELLOW}Mostrando logs de ${PODS[$POD_INDEX]}...${NC}"
        echo -e "${YELLOW}Pressione Ctrl+C para sair${NC}"
        echo ""
        kubectl logs -f ${PODS[$POD_INDEX]} -n $NAMESPACE
    else
        echo -e "${RED}Opcao invalida${NC}"
        sleep 2
    fi
}

function restart() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        Reiniciar Pods                 ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Reiniciando todos os pods...${NC}"
    kubectl rollout restart deployment/$APP_NAME -n $NAMESPACE
    
    echo -e "${YELLOW}Aguardando rollout...${NC}"
    kubectl rollout status deployment/$APP_NAME -n $NAMESPACE
    
    echo -e "${GREEN}Pods reiniciados!${NC}"
    sleep 2
}

function test_connectivity() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}      Teste de Conectividade           ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    NODEPORT=$(kubectl get service nginx-service -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')
    
    echo -e "${YELLOW}1) Teste interno (localhost):${NC}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$NODEPORT)
    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "${GREEN}OK - Codigo: $HTTP_CODE${NC}"
    else
        echo -e "${RED}FALHOU - Codigo: $HTTP_CODE${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}2) Teste via service name:${NC}"
    kubectl run test-curl --image=curlimages/curl --rm -i --restart=Never -n $NAMESPACE -- \
        curl -s -o /dev/null -w "Status: %{http_code}\n" http://nginx-service 2>/dev/null || echo -e "${RED}Falhou${NC}"
    echo ""
    
    PUBLIC_IP=$(curl -s ifconfig.me)
    echo -e "${YELLOW}3) URL de acesso externo:${NC}"
    echo -e "${GREEN}http://$PUBLIC_IP:$NODEPORT${NC}"
    echo ""
    
    read -p "Pressione ENTER para continuar..."
}

function update_image() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}       Atualizar Imagem Docker         ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Imagem atual:${NC}"
    CURRENT_IMAGE=$(kubectl get deployment $APP_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')
    echo -e "${GREEN}$CURRENT_IMAGE${NC}"
    echo ""
    
    read -p "Nova imagem (ex: nginx:1.26-alpine): " new_image
    
    if [ -z "$new_image" ]; then
        echo -e "${RED}Imagem nao pode ser vazia${NC}"
        sleep 2
        return
    fi
    
    echo -e "${YELLOW}Atualizando imagem...${NC}"
    kubectl set image deployment/$APP_NAME nginx=$new_image -n $NAMESPACE
    
    echo -e "${YELLOW}Aguardando rollout...${NC}"
    kubectl rollout status deployment/$APP_NAME -n $NAMESPACE
    
    echo -e "${GREEN}Imagem atualizada!${NC}"
    sleep 2
}

function delete() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}    DELETAR APLICACAO                  ${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    
    read -p "Tem CERTEZA que deseja deletar TUDO? Digite 'DELETAR' para confirmar: " confirm
    
    if [ "$confirm" == "DELETAR" ]; then
        echo -e "${YELLOW}Deletando recursos...${NC}"
        kubectl delete -f ~/k8s-manifests/nginx-deployment-custom.yaml 2>/dev/null || true
        kubectl delete -f ~/k8s-manifests/nginx-service.yaml 2>/dev/null || true
        kubectl delete -f ~/k8s-manifests/nginx-configmap.yaml 2>/dev/null || true
        echo -e "${GREEN}Aplicacao deletada${NC}"
    else
        echo -e "${YELLOW}Operacao cancelada${NC}"
    fi
    
    sleep 2
}

# Loop principal
while true; do
    show_menu
done
