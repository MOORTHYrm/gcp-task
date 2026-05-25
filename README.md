# 🚀 Python App — Full GCP DevOps Pipeline

> **Production-grade CI/CD pipeline** deploying a Python Flask application to Google Kubernetes Engine using GitHub Actions, Terraform, Helm, and ArgoCD.

[![CI/CD Pipeline](https://github.com/MOORTHYrm/gcp-task/actions/workflows/build-deploy.yml/badge.svg)](https://github.com/MOORTHYrm/gcp-task/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.12-blue?logo=python)](https://python.org)
[![Terraform](https://img.shields.io/badge/Terraform-1.5.0-purple?logo=terraform)](https://terraform.io)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.35-blue?logo=kubernetes)](https://kubernetes.io)

---

## 🌐 Live Endpoints

| Service | URL | Description |
|---|---|---|
| 🌍 Application | [https://devopstrends.online](https://devopstrends.online) | Production Flask app |
| 📊 Monitoring | [https://monitor.devopstrends.online](https://monitor.devopstrends.online) | Grafana / Prometheus |
| 🔄 GitOps (ArgoCD) | [http://argocd.devopstrends.online](https://argocd.devopstrends.online) | ArgoCD CD dashboard |

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Tech Stack](#-tech-stack)
- [Repository Structure](#-repository-structure)
- [Infrastructure (Terraform)](#-infrastructure-terraform)
- [Docker](#-docker)
- [Kubernetes & Helm](#-kubernetes--helm)
- [CI/CD Pipeline](#-cicd-pipeline)
- [GitOps with ArgoCD](#-gitops-with-argocd)
- [Monitoring](#-monitoring)
- [DNS & SSL](#-dns--ssl)
- [CI/CD Best Practices](#-cicd-best-practices)
- [Getting Started](#-getting-started)
- [Secrets Reference](#-secrets-reference)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Developer Workflow                           │
│                                                                     │
│   git push → GitHub → GitHub Actions CI/CD → GKE (Production)      │
└─────────────────────────────────────────────────────────────────────┘

                         ┌──────────────────┐
                         │   GitHub Repo    │
                         │  (Source + Helm) │
                         └────────┬─────────┘
                                  │ push to main
                                  ▼
                    ┌─────────────────────────────┐
                    │     GitHub Actions CI/CD     │
                    │                             │
                    │  1. Lint & Test (Flake8)    │
                    │  2. Secret Scan (Gitleaks)  │
                    │  3. Build & Push (Docker)   │
                    │  4. Trivy Scan (HIGH/CRIT)  │
                    │  5. Helm Lint & Dry-run     │
                    │  6. Deploy via Helm → GKE   │
                    │  7. ArgoCD Sync             │
                    │  8. Slack Notification      │
                    └──────────────┬──────────────┘
                                   │
               ┌───────────────────┼───────────────────┐
               │                   │                   │
               ▼                   ▼                   ▼
   ┌───────────────────┐ ┌─────────────────┐ ┌─────────────────────┐
   │  Artifact Registry│ │   GKE Cluster   │ │     ArgoCD          │
   │  (Docker Images)  │ │  us-central1-a  │ │  GitOps Sync        │
   │                   │ │                 │ │  argocd.devops...   │
   │  python-app:sha   │ │  ┌───────────┐  │ └─────────────────────┘
   │  python-app:latest│ │  │  2 Nodes  │  │
   └───────────────────┘ │  │ e2-medium │  │
                         │  └─────┬─────┘  │
                         │        │        │
                         │  ┌─────▼──────┐ │
                         │  │    Pod     │ │
                         │  │ (1 replica)│ │
                         │  │  Flask App │ │
                         │  └─────┬──────┘ │
                         └────────┼────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │     GCP Load Balancer       │
                    │   + Cloud DNS (GoDaddy)     │
                    │   + SSL Certificate         │
                    └─────────────┬──────────────┘
                                  │
              ┌───────────────────┼──────────────────┐
              ▼                   ▼                  ▼
   devopstrends.online  monitor.devopstrends.online  argocd.devopstrends.online
```

---

## 🛠️ Tech Stack

### Application
| Layer | Technology | Version |
|---|---|---|
| Language | Python | 3.12 |
| Framework | Flask + Gunicorn | latest |
| Container | Docker (distroless/slim) | — |
| Base Image | `python:3.12-slim` | official |

### Infrastructure (Terraform on GCP)
| Resource | Details |
|---|---|
| Provider | `hashicorp/google` v5.0 |
| Terraform | v1.5.0 |
| GKE Cluster | us-central1-a, 2 nodes, e2-medium |
| Artifact Registry | Docker image repository |
| Cloud Storage | Terraform state backend (versioned) |
| Cloud DNS | Zone for `devopstrends.online` |
| VPC & Compute | Custom network, firewall rules |
| Load Balancer | External HTTP(S) with managed SSL |
| IAM | Service accounts + least-privilege roles |

### Kubernetes
| Component | Details |
|---|---|
| Version | 1.35 |
| Nodes | 2 × e2-medium |
| Workload | Deployment (1 pod replica) |
| Namespace | `default` |
| Storage | PV / PVC with dynamic provisioner |
| Networking | Ingress + ExternalLoadBalancer + ClusterIP |
| RBAC | Role + RoleBinding |

### CI/CD & GitOps
| Tool | Purpose |
|---|---|
| GitHub Actions | CI/CD automation |
| Helm v3.14 | Kubernetes package manager |
| ArgoCD | GitOps continuous delivery |
| Gitleaks | Secret scanning |
| Trivy v0.36 | Container vulnerability scanning |
| Flake8 / Ruff | Python linting |

### Observability & DNS
| Tool | Purpose | URL |
|---|---|---|
| Grafana | Dashboards | monitor.devopstrends.online username: admin pass: Admin@123 |
| Prometheus | Metrics scraping | Internal |
| GoDaddy | Domain registrar | — |
| Cloud DNS | DNS zone management | — |
| Let's Encrypt / GCP SSL | TLS certificates | — |

---

## 📁 Repository Structure

```
gcp-task/
│
├── .github/
│   └── workflows/
│       └── build-deploy.yml        # Main CI/CD pipeline (8 jobs)
│
├── helm/
│   └── python-app/
│       ├── Chart.yaml
│       ├── values.yaml             # image.tag auto-updated by CI
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── hpa.yaml
│           └── _helpers.tpl
│
├── terraform/
│   ├── main.tf                     # GKE, IAM, Artifact Registry, DNS
│   ├── variables.tf                # Input variable declarations
│   ├── outputs.tf                  # Cluster endpoint, registry URL
│   ├── providers.tf                # google provider v5.0
│   └── backend.tf                  # GCS remote state + versioning
│
├── k8s/                            # Raw manifests (ArgoCD source of truth)
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── pv.yaml
│   ├── pvc.yaml
│   └── rbac/
│       ├── role.yaml
│       └── rolebinding.yaml
│
|
|          
│
├── app.py                          # Flask application
├── requirements.txt
├── Dockerfile                      # Multi-stage, distroless slim
├── .dockerignore
|       # Gitleaks, Ruff, Hadolint, etc.
├── .env.example
├── .gitignore
└── README.md
```

---

## 🌍 Infrastructure (Terraform)

### Backend — Remote State with GCS

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket  = "tf-state-gcp-task"
    prefix  = "terraform/state"
  }
}
```

The GCS bucket is configured with:
- **Versioning enabled** — every state file version is retained
- **Soft delete** — protects against accidental deletion
- **Uniform bucket-level access** — no per-object ACLs

### Key Resources

```hcl
# GKE Cluster
resource "google_container_cluster" "prod" {
  name     = "prod-cluster"
  location = "us-central1-a"

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 50
  }

  node_count = 2
}

# Protect production from accidental terraform destroy
resource "google_container_cluster" "prod" {
  lifecycle {
    prevent_destroy = true
  }
}
```

### Resources Provisioned

```
GCP Project
├── VPC Network + Subnets + Firewall Rules
├── GKE Cluster (prod-cluster, us-central1-a, 2 × e2-medium)
├── Artifact Registry (Docker repository: pythontest)
├── Cloud Storage (Terraform state bucket — versioned)
├── Cloud DNS (Zone: devopstrends.online)
├── External Load Balancer + Managed SSL
├── Service Account (CI/CD + GKE workloads)
└── IAM Bindings
    ├── roles/artifactregistry.writer
    ├── roles/container.developer
    ├── roles/dns.admin
    └── roles/storage.objectAdmin
```

### Deploying Infrastructure

```bash
# 1. Authenticate
gcloud auth application-default login

# 2. Init with remote backend
cd terraform/
terraform init

# 3. Plan — review all changes
terraform plan -out=tfplan

# 4. Apply
terraform apply tfplan

# 5. Get GKE credentials
gcloud container clusters get-credentials prod-cluster \
  --zone us-central1-a \
  --project <PROJECT_ID>
```

---

## 🐳 Docker

### Multi-Stage Build Strategy

The Dockerfile uses a **two-stage build** to minimize the final image size and attack surface:

```
Stage 1 (builder)  →  Compiles Python wheels (includes gcc, build tools)
Stage 2 (runtime)  →  Copies only .whl files, no compiler, no cache
```

| Property | Value |
|---|---|
| Base image | `python:3.12-slim` (official) |
| Final image size | ~80-100 MB (vs ~300 MB with full Python) |
| User | Non-root `appuser` (security hardened) |
| Worker class | `gthread` (concurrent I/O) |
| Gunicorn workers | Configurable via `WORKERS` env var |

### Build & Run Locally

```bash
# Build
docker build -t python-app:local .

# Run (override workers at runtime — no rebuild needed)
docker run -p 8080:8080 \
  -e WORKERS=4 \
  -e THREADS=4 \
  python-app:local

# Scan locally before pushing
trivy image --severity HIGH,CRITICAL python-app:local
```

### Image Tagging Strategy

| Tag | Example | When |
|---|---|---|
| `SHORT_SHA` | `1aa452e` | Every main push — immutable |
| `latest` | `latest` | Always points to newest build |

---

## ☸️ Kubernetes & Helm

### Cluster Layout

```
GKE prod-cluster (us-central1-a)
└── Namespace: default
    ├── Deployment: python-app (1 replica)
    │   └── Pod: python-app-xxx
    │       └── Container: python-app:1aa452e
    ├── Service: python-app (ClusterIP)
    ├── Service: python-app-lb (ExternalLoadBalancer)
    ├── Ingress: python-app (routes → LoadBalancer)
    ├── PersistentVolume (dynamic provisioner)
    ├── PersistentVolumeClaim
    ├── Role: python-app-role
    └── RoleBinding: python-app-rolebinding
```

### Helm Chart

Helm manages all Kubernetes manifests. The `image.tag` in `values.yaml` is auto-updated by the CI pipeline on every successful build:

```yaml
# helm/python-app/values.yaml
image:
  repository: us-central1-docker.pkg.dev/project-xxx/pythontest/python-app
  tag: "1aa452e"    # ← auto-updated by GitHub Actions on every push

replicaCount: 1

resources:
  requests:
    cpu: 50m
    memory: 128Mi
  limits:
    cpu: 100m
    memory: 256Mi
```

### Helm Commands

```bash
# Install / upgrade
helm upgrade --install python-app ./helm/python-app \
  --namespace default \
  --set image.tag=1aa452e \
  --atomic --wait --timeout 10m

# Rollback to previous version
helm rollback python-app 1 -n default

# View release history
helm history python-app -n default

# Dry-run (validate before apply)
helm template python-app ./helm/python-app --debug
```

---

## ⚙️ CI/CD Pipeline

The pipeline runs on every push to `main`. All 8 jobs must pass for a successful deployment.

### Pipeline Flow

```
push to main
     │
     ├──── Job 1: Lint & Test ──────────────────────────────── [parallel]
     │     └── Flake8 on app.py
     │
     ├──── Job 2: Secret Scanning ──────────────────────────── [parallel]
     │     └── Gitleaks full history scan
     │
     │     (both must pass)
     │
     └──── Job 3: Build & Push ─────────────────────────────── [sequential]
           ├── Authenticate to GCP (Workload Identity)
           ├── Build Docker image (multi-stage)
           ├── Push to Artifact Registry (sha + latest tags)
           └── GitOps: update image.tag in values.yaml → push
                │
                └──── Job 4: Trivy Scan ──────────────────────
                      ├── Scan for HIGH + CRITICAL CVEs
                      ├── exit-code: 1 → blocks pipeline if found
                      └── Upload SARIF → GitHub Security tab
                           │
                           └──── Job 5: Helm Lint ──────────────
                                 ├── helm lint
                                 └── helm template dry-run
                                      │
                                      └──── Job 6: Deploy ────────
                                            ├── Get GKE credentials
                                            ├── Clear stuck Helm release
                                            ├── helm upgrade --install
                                            │   --atomic --wait 10m
                                            └── Verify: pods, svc, ingress
                                                 │
                                                 └──── Job 7: ArgoCD Sync
                                                       ├── argocd app sync
                                                       └── argocd app wait
                                                            │
                                                            └──── Job 8: Slack
                                                                  ✅ or ❌
```

### Job Summary

| Job | Needs | Blocks if fails | What it does |
|---|---|---|---|
| `test` | — | Yes | Flake8 Python lint |
| `gitleaks` | — | Yes | Secret scanning across full git history |
| `build-push` | test, gitleaks | Yes | Build → push image, update values.yaml |
| `trivy-scan` | build-push | Yes | CVE scan HIGH/CRITICAL; upload SARIF |
| `helm-lint` | trivy-scan | Yes | Helm lint + template dry-run |
| `deploy` | build-push, helm-lint | Yes | Helm upgrade → GKE with rollback on failure |
| `argocd-sync` | deploy | Yes | Force sync + health check |
| `slack-notify` | all | No | Send success/failure to Slack |

### Authentication — Workload Identity Federation

No long-lived service account keys are stored. GitHub OIDC tokens authenticate directly to GCP:

```yaml
- name: Authenticate to GCP
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
    service_account: ${{ secrets.GCP_SA_EMAIL }}
```

---

## 🔄 GitOps with ArgoCD

ArgoCD watches the `helm/python-app/values.yaml` in this repository. When the CI pipeline updates `image.tag` and pushes, ArgoCD detects the drift and syncs the cluster.

### Sync Flow

```
GitHub Actions pushes new image.tag to values.yaml
          │
          ▼
    ArgoCD detects drift (polling every 3 min or webhook)
          │
          ▼
    argocd app sync python-app --force
          │
          ▼
    GKE cluster updated to new image
          │
          ▼
    argocd app wait --sync --health --timeout 300
          │
          ▼
    ✅ Healthy — Slack notified
```

### ArgoCD Access

```bash
# Login via CLI
argocd login argocd.devopstrends.online \
  --username admin \
  --password <ARGOCD_PASSWORD>

# Check app status
argocd app get python-app

# Manual sync (if needed)
argocd app sync python-app

# Rollback
argocd app rollback python-app <revision>
```

**Dashboard:** [http://argocd.devopstrends.online](http://argocd.devopstrends.online)

---

## 📊 Monitoring

Prometheus + Grafana are deployed in the cluster and exposed via subdomain.

**Dashboard:** [https://monitor.devopstrends.online](https://monitor.devopstrends.online)

| Metric | Source |
|---|---|
| Pod CPU / Memory | kube-state-metrics |
| HTTP request rate | Prometheus Flask exporter |
| Deployment health | Kubernetes API |
| Node utilization | node-exporter |

---

## 🌐 DNS & SSL

Domain `devopstrends.online` is registered on **GoDaddy** with nameservers pointed to **Google Cloud DNS**.

```
GoDaddy (Registrar)
  └── Nameservers → Cloud DNS (ns-cloud-*.googledomains.com)
        └── Cloud DNS Zone: devopstrends.online
              ├── A record: devopstrends.online → GCP External LB IP
              ├── A record: monitor.devopstrends.online → GCP External LB IP
              └── A record: argocd.devopstrends.online → GCP External LB IP

GCP Managed SSL Certificate
  └── Covers: devopstrends.online
              monitor.devopstrends.online
              argocd.devopstrends.online
```

### Configure DNS (one-time)

```bash
# Get Load Balancer external IP
kubectl get ingress -n default

# Update Cloud DNS A records
gcloud dns record-sets create devopstrends.online. \
  --zone=devopstrends-zone \
  --type=A \
  --ttl=300 \
  --rrdatas=<LB_EXTERNAL_IP>
```

---

## ✅ CI/CD Best Practices

### Security

- **Workload Identity Federation** — no static service account keys in GitHub secrets
- **Gitleaks** — scans full git history on every push; blocks commit if secrets found
- **Trivy** — blocks deploy if HIGH or CRITICAL CVEs found in the image
- **Non-root container** — `appuser` with no home directory
- **Distroless slim base** — minimal OS surface area
- **`prevent_destroy`** — Terraform lifecycle block protects production GKE cluster
- **Sensitive outputs** — marked `sensitive = true` in Terraform outputs

### Reliability

- `--atomic` on Helm deploy — auto-rollback if pods fail to become healthy
- `--wait --timeout 10m` — Helm waits for rollout before declaring success
- Stuck Helm release detection — clears `pending-*` states before upgrade
- `--history-max 5` — keeps last 5 Helm releases for rollback
- `--max-requests 1000` — Gunicorn worker recycling prevents memory leaks

### Speed

- **Parallel jobs** — `test` and `gitleaks` run simultaneously
- **Docker layer caching** — `requirements.txt` copied before `app.py`
- **pip `cache: pip`** — GitHub Actions caches pip packages between runs
- **Multi-stage build** — builder stage never ships to production
- **`[skip ci]`** tag — values.yaml update commit doesn't re-trigger the pipeline

### Branch & Commit Standards

- `main` branch is **protected** — requires passing CI + 1 review
- **Conventional Commits** enforced via `commit-msg` pre-commit hook
- All feature work in `feat/*`, fixes in `fix/*`, never direct push to `main`
- PR titles follow the same `type(scope): description` format

### Observability

- Gunicorn logs to stdout/stderr — captured by GKE logging automatically
- SARIF reports uploaded to GitHub Security tab on every scan (pass or fail)
- Slack notification on every `main` push — per-job status included
- ArgoCD dashboard shows sync history and health over time

---

## 🚀 Getting Started

### Prerequisites

```bash
# Tools required
python --version    # 3.12+
git --version       # 2.43+
terraform version   # 1.5.0+
helm version        # v3.14.0+
kubectl version     # 1.35+
gcloud version      # latest
docker --version    # latest
```

### 1. Clone & Setup

```bash
git clone https://github.com/MOORTHYrm/gcp-task.git
cd gcp-task

### 2. Provision Infrastructure

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### 3. Configure GitHub Secrets

Go to **Settings → Secrets → Actions** and add:

| Secret | Description |
|---|---|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | WIF provider resource name |
| `GCP_SA_EMAIL` | CI service account email |
| `ARGOCD_SERVER` | `argocd.devopstrends.online` |
| `ARGOCD_PASSWORD` | ArgoCD admin password |
| `SLACK_WEBHOOK_URL` | Slack Incoming Webhook URL |
| `GITLEAKS_LICENSE` | Gitleaks pro license (optional) |

### 4. Deploy

```bash
# Any push to main triggers the full 8-job pipeline
git push origin main

# Monitor at:
# https://github.com/MOORTHYrm/gcp-task/actions
# https://argocd.devopstrends.online
# https://monitor.devopstrends.online
```

---

## 🔐 Secrets Reference

| Secret / Variable | Where Used | Sensitive |
|---|---|---|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | GitHub Actions → GCP auth | ✅ |
| `GCP_SA_EMAIL` | GitHub Actions → GCP auth | ✅ |
| `ARGOCD_SERVER` | ArgoCD CLI login | — |
| `ARGOCD_PASSWORD` | ArgoCD CLI login | ✅ |
| `SLACK_WEBHOOK_URL` | Slack notification | ✅ |
| `GITLEAKS_LICENSE` | Gitleaks pro | ✅ |
| `GITHUB_TOKEN` | Auto-provided by GitHub Actions | — |

> ⚠️ **Never** commit `.env`, `.env.local`, `*.pem`, `*.key`, or any credential file. Pre-commit hooks and Gitleaks will block it — but the best defence is awareness.

---

## 📄 License

MIT © [MOORTHYrm](https://github.com/MOORTHYrm)
