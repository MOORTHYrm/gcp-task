# GCP Python App — GKE Deployment

## Architecture

```
GitHub Push → GitHub Actions CI/CD
    ├── Lint & Test
    ├── Build Docker → Artifact Registry (pythontest)
    └── Deploy → GKE Cluster (prod-cluster, us-central1-a)
                     └── Google Cloud Load Balancer
                              └── devopstrends.online (SSL)
```

## Resources Created by Terraform

| Resource | Name |
|---|---|
| GKE Cluster | `prod-cluster` |
| Node Pool | `prod-cluster-node-pool` |
| Artifact Registry | `pythontest` |
| Load Balancer IP | `python-app-lb-ip` |
| Cloud DNS Zone | `prod-zone` → `devopstrends.online` |
| CI/CD SA | `github-actions-sa` |

---

## Step 1 — Terraform Setup

```bash
cd terraform

# Initialise
terraform init

# Preview
terraform plan

# Apply (creates all GCP infra)
terraform apply -auto-approve

# Get the static LB IP
terraform output load_balancer_ip

# Get the GitHub Actions SA key (base64)
terraform output -raw github_actions_sa_key
```

> ⚠️ After `apply`, copy the `github_actions_sa_key` output. You will need it in Step 2.

---

## Step 2 — Add GitHub Secrets

Go to your repo → **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
|---|---|
| `GCP_SA_KEY` | Paste the full base64 JSON output from `terraform output -raw github_actions_sa_key` |

---

## Step 3 — Point Your Domain to GCP DNS

After `terraform apply`, run:
```bash
terraform output dns_nameservers
```
Copy the 4 nameservers and update your domain registrar (wherever devopstrends.online is registered) to use these Cloud DNS nameservers.

---

## Step 4 — Push & Deploy

```bash
git remote add origin https://github.com/MOORTHYrm/gcp-task.git
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will automatically:
1. Run lint/tests
2. Build & push Docker image to `pythontest` Artifact Registry
3. Deploy to GKE with rolling update
4. Configure HTTPS via Google Managed Certificate

---

## Local Development

```bash
# Run locally
pip install -r requirements.txt
python app.py

# Docker local test
docker build -t python-app .
docker run -p 8080:8080 python-app

# Visit http://localhost:8080
```

---

## Verify in Production

```bash
# Get cluster credentials
gcloud container clusters get-credentials prod-cluster \
  --zone us-central1-a \
  --project project-6b73a1f9-ef42-4074-81a

# Check pods
kubectl get pods

# Check ingress & certificate status
kubectl get managedcertificate
kubectl describe ingress python-app-ingress
```

---

## Image URL Format

```
us-central1-docker.pkg.dev/project-6b73a1f9-ef42-4074-81a/pythontest/python-app:<tag>
```
# gcp-task
