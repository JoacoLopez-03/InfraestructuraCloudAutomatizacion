# Proyecto Final DevOps — Pipeline CI/CD Completo

Pipeline profesional de extremo a extremo: **build → test → seguridad → imagen Docker → infraestructura (Terraform) → despliegue en Kubernetes (EKS) → monitoreo (Prometheus/Grafana) → FinOps**.

> **Estado del proyecto:** los jobs de calidad, testing y seguridad estática (SAST) se ejecutan de forma reproducible sin infraestructura externa. Los jobs que requieren una cuenta de AWS real (push a ECR, Terraform, deploy a EKS, DAST) están implementados y se activan condicionalmente mediante la variable `AWS_ENABLED`. Ver la sección [Qué corre sin AWS](#qué-corre-sin-aws-y-qué-requiere-aws).

## Arquitectura

```
GitHub push → GitHub Actions
   ├─ Build & Test (Jest) + Lint (ESLint)      [siempre]
   ├─ SAST (CodeQL)                            [siempre]
   ├─ Docker build → Trivy scan → push a ECR   [requiere AWS]
   ├─ Terraform apply (VPC + EKS + ECR)        [requiere AWS]
   ├─ kubectl apply (Deployment/Service/Ingress/HPA) [requiere AWS]
   └─ DAST (OWASP ZAP)                         [requiere AWS]
Kubernetes (EKS) → Prometheus scrape /metrics → Grafana dashboards
```

## Prerrequisitos

| Herramienta | Versión mínima | Para qué |
|-------------|----------------|----------|
| Node.js     | 20+            | Ejecutar y testear la app |
| Docker      | 24+            | Construir la imagen y el stack local |
| Terraform   | 1.5+           | Aprovisionar la infraestructura |
| kubectl     | 1.28+          | Desplegar en Kubernetes |
| AWS CLI     | 2+             | Autenticación y acceso a EKS/ECR (solo modo AWS) |

## Secrets y variables de GitHub Actions

Configurar en **Settings → Secrets and variables → Actions**.

| Nombre | Tipo | Requerido para | Descripción |
|--------|------|----------------|-------------|
| `AWS_ACCESS_KEY_ID`     | Secret   | Jobs AWS | Clave de acceso IAM |
| `AWS_SECRET_ACCESS_KEY` | Secret   | Jobs AWS | Clave secreta IAM |
| `ECR_REGISTRY`          | Secret   | Deploy   | URL del registry ECR |
| `AWS_ENABLED`           | Variable | Activar jobs AWS | Poner en `true` para habilitar los jobs de infraestructura |

Sin `AWS_ENABLED=true`, los jobs de AWS se omiten y el pipeline queda en verde solo con calidad y seguridad. Las credenciales nunca se escriben en el código.

## Ejecutar en local

```bash
# App + tests
cd app && npm ci && npm test && npm start
# App en http://localhost:3000

# Stack completo (app + Prometheus + Grafana)
cd monitoring && docker-compose up --build
# App:        http://localhost:3000
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3001  (admin / admin)
```

**Resultado esperado de los tests:**
```
Test Suites: 1 passed, 1 total
Tests:       4 passed, 4 total
Cobertura:   96.55% de líneas
```

## Validar el código antes de desplegar

```bash
# Terraform
cd terraform && terraform fmt -check && terraform init && terraform validate

# Kubernetes (dry-run contra el esquema, sin cluster)
kubectl apply --dry-run=client -f k8s/
# o con kubeconform:
kubeconform -strict -summary k8s/*.yaml
```
**Resultado esperado (K8s):** `Valid: 5, Invalid: 0, Errors: 0`. Ver `docs/evidencias/k8s-validacion.txt`.

## Desplegar infraestructura (modo AWS)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # ajustar valores
terraform init && terraform plan && terraform apply
aws eks update-kubeconfig --region us-east-1 --name devops-final-dev-eks
```
> El backend S3 remoto está comentado en `versions.tf`. Por defecto usa estado local (funciona sin infra previa). Para trabajo en equipo, cree el bucket + tabla DynamoDB y descoméntelo.

## Desplegar la aplicación

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
curl localhost:8080/metrics                # métricas Prometheus
```
En Grafana, importar `monitoring/grafana/dashboards/app-dashboard.json`.

## Qué corre sin AWS y qué requiere AWS

| Etapa | Sin AWS | Con AWS (`AWS_ENABLED=true`) |
|-------|:-------:|:----------------------------:|
| Build & Test (Jest/ESLint) | ✅ | ✅ |
| SAST (CodeQL) | ✅ | ✅ |
| Validación K8s (dry-run) | ✅ | ✅ |
| `terraform validate` | ✅ | ✅ |
| Build imagen Docker (local) | ✅ | ✅ |
| Push a ECR | — | ✅ |
| Terraform apply (infra real) | — | ✅ |
| Deploy a EKS | — | ✅ |
| Trivy / DAST sobre entorno real | — | ✅ |

## Seguridad (DevSecOps)

| Etapa | Herramienta | Momento |
|-------|-------------|---------|
| SAST  | CodeQL      | En cada push/PR |
| Imagen| Trivy 0.24.0| Antes del push a ECR |
| DAST  | OWASP ZAP   | Tras el despliegue |

## FinOps

- Nodos **SPOT** en EKS (hasta ~70% de ahorro).
- **Un solo NAT Gateway** en entornos no productivos.
- **ECR lifecycle policy**: conserva solo 10 imágenes.
- **HPA** con ventana de estabilización para evitar sobre-escalado.
- **Script de apagado programado** (`scripts/finops-scheduler.sh`) para escalar a 0 fuera de horario.

## Estructura del repositorio

```
.
├── app/                    # App Node.js/Express + tests
├── docker/                 # Dockerfile multi-stage + .dockerignore
├── terraform/              # IaC: VPC, EKS, ECR (módulos reutilizables)
│   └── modules/{network,eks}
├── k8s/                    # Manifiestos: namespace, deployment, service, ingress, hpa
├── monitoring/             # Prometheus + Grafana + docker-compose
├── scripts/                # FinOps: apagado programado
├── .github/workflows/      # Pipeline CI/CD
└── docs/evidencias/        # Logs y salidas de ejecución
```
