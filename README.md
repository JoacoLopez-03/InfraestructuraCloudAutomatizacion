# Proyecto Final DevOps — Pipeline CI/CD Completo

Pipeline profesional de extremo a extremo: **build → test → seguridad → imagen Docker → infraestructura (Terraform) → despliegue en Kubernetes (EKS) → monitoreo (Prometheus/Grafana) → FinOps**.

## Arquitectura

```
GitHub push → GitHub Actions
   ├─ Build & Test (Jest) + Lint (ESLint)
   ├─ SAST (CodeQL)
   ├─ Docker build → Trivy scan → push a ECR
   ├─ Terraform apply (VPC + EKS + ECR)
   ├─ kubectl apply (Deployment/Service/Ingress/HPA)
   └─ DAST (OWASP ZAP) sobre el entorno desplegado
Kubernetes (EKS) → Prometheus scrape /metrics → Grafana dashboards
```

## Estructura del repositorio

```
.
├── app/                    # Aplicacion Node.js/Express + tests
├── docker/                 # Dockerfile multi-stage + .dockerignore
├── terraform/              # IaC: VPC, EKS, ECR (modulos reutilizables)
│   └── modules/{network,eks}
├── k8s/                    # Manifiestos: namespace, deployment, service, ingress, hpa
├── monitoring/             # Prometheus + Grafana + docker-compose local
├── scripts/                # FinOps: apagado programado del cluster
├── .github/workflows/      # Pipeline CI/CD
└── docs/evidencias/        # Logs y salidas de ejecucion
```

## Requisitos previos

- Node.js 20+, Docker, Terraform 1.5+, kubectl, AWS CLI configurado.
- Un bucket S3 y una tabla DynamoDB para el estado remoto de Terraform.

## Ejecutar en local

```bash
# App + tests
cd app && npm ci && npm test && npm start

# Stack completo (app + Prometheus + Grafana)
cd monitoring && docker-compose up --build
# App:        http://localhost:3000
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3001  (admin / admin)
```

## Desplegar infraestructura

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # ajustar valores
terraform init && terraform plan && terraform apply
aws eks update-kubeconfig --region us-east-1 --name devops-final-dev-eks
```

## Desplegar la aplicacion

```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/
kubectl -n demo-app rollout status deployment/web
kubectl -n demo-app get pods,svc,ingress,hpa
```

## Validar despliegue y monitoreo

```bash
kubectl -n demo-app get hpa web-hpa        # ver auto-escalado
kubectl -n demo-app port-forward svc/web-svc 8080:80
curl localhost:8080/metrics                # metricas Prometheus
```
En Grafana, importar `monitoring/grafana/dashboards/app-dashboard.json`.

## Seguridad (DevSecOps)

| Etapa | Herramienta | Momento |
|-------|-------------|---------|
| SAST  | CodeQL      | En cada push/PR |
| Imagen| Trivy       | Antes del push a ECR |
| DAST  | OWASP ZAP   | Tras el despliegue |

Credenciales gestionadas con **GitHub Secrets** (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `ECR_REGISTRY`). Nunca se exponen en el código.

## FinOps

- Nodos **SPOT** en EKS (hasta ~70% de ahorro).
- **Un solo NAT Gateway** en entornos no productivos.
- **ECR lifecycle policy**: conserva solo 10 imágenes.
- **HPA** con ventana de estabilización para evitar sobre-escalado.
- **Script de apagado programado** (`scripts/finops-scheduler.sh`) para escalar a 0 fuera de horario.

## Secretos requeridos en GitHub Actions

`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `ECR_REGISTRY`.
