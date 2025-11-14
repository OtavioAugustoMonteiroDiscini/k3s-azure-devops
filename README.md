# 🚀 K3s no Azure - Projeto DevOps

Implementação completa de Kubernetes (K3s) em VM Azure para estudantes.

## 📋 Arquitetura
```
┌─────────────────────────────────────┐
│         Azure Cloud                 │
│  ┌───────────────────────────────┐  │
│  │  VM Ubuntu 22.04 (B2s)        │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │      K3s Cluster        │  │  │
│  │  │  ┌──────────────────┐   │  │  │
│  │  │  │  Nginx Pods (3x) │   │  │  │
│  │  │  └──────────────────┘   │  │  │
│  │  │  ┌──────────────────┐   │  │  │
│  │  │  │ Service NodePort │   │  │  │
│  │  │  └──────────────────┘   │  │  │
│  │  └─────────────────────────┘  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## 🛠️ Tecnologias

- **Cloud**: Microsoft Azure (Azure for Students)
- **Orquestração**: K3s (Kubernetes leve)
- **Container Runtime**: Docker
- **CI/CD**: GitHub Actions
- **Aplicação**: Nginx

## 📦 Estrutura do Projeto
```
projeto-k8s/
├── .github/
│   └── workflows/
│       ├── deploy-k8s.yml
│       └── ci-pull-request.yml
├── manifests/
│   ├── nginx-configmap.yaml
│   ├── nginx-deployment-custom.yaml
│   └── nginx-service.yaml
├── scripts/
│   ├── deploy-nginx.sh
│   ├── manage-app.sh
│   └── backup-k8s.sh
└── docs/
    └── SETUP.md
```

## 🚀 Deploy Automático

Cada push na branch `main` dispara automaticamente:

1. ✅ Validação de YAML
2. 🔍 Dry-run dos manifestos
3. 📦 Deploy no cluster K3s
4. ✔️ Testes de conectividade

## 💻 Comandos Úteis
```bash
# Deploy manual
./scripts/deploy-nginx.sh

# Gerenciamento interativo
./scripts/manage-app.sh

# Backup
./scripts/backup-k8s.sh
```

## 🌐 Acesso

- **Produção**: http://<IP_PUBLICO>:30080
- **Namespace**: producao
- **Réplicas**: 3 pods

## 📊 Recursos

- **CPU Request**: 100m por pod
- **Memory Request**: 64Mi por pod
- **CPU Limit**: 200m por pod
- **Memory Limit**: 128Mi por pod

## 🔐 Secrets Necessários

Configure no GitHub:
- `SSH_PRIVATE_KEY`: Chave privada SSH da VM
- `SSH_HOST`: IP público da VM
- `SSH_USER`: azureuser

## 📝 Licença

MIT License - Projeto educacional
