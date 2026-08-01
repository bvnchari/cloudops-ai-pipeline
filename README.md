# CloudOps-AI — Multi-Cloud Pipeline

One GitHub Actions workflow (`cloudops-ai-multicloud.yml`) that builds the
entire stack — cluster + registry + monitoring + app — on **Azure, GCP, or
AWS**, picked by a dropdown, and tears it all down again. Reusable across any
app: just change `app_source` to a different GitHub repo or HuggingFace Space
git URL (`https://huggingface.co/spaces/<user>/<space>`).

## Folder layout

```
azure/   → AKS + ACR (Terraform, state in Azure Storage)
gcp/     → GKE Autopilot + Artifact Registry (Terraform, state in GCS)
aws/     → EKS + ECR (Terraform, state in S3)
k8s/     → shared app-deployment.yaml template (image gets swapped in per run)
.github/workflows/cloudops-ai-multicloud.yml
```

Each cloud folder is self-contained Terraform (own provider, own backend,
own state file) — the workflow just `cd`s into whichever one you pick.

## One-time setup — do once per cloud you plan to use

### Azure
```bash
az group create -n cloudops-ai-tfstate-rg -l centralindia
az storage account create -n cloudopsaitfstate -g cloudops-ai-tfstate-rg -l centralindia --sku Standard_LRS
az storage container create -n tfstate --account-name cloudopsaitfstate

az ad sp create-for-rbac --name "cloudops-ai-gha" --role Contributor \
  --scopes /subscriptions/<sub-id> --sdk-auth
# → paste JSON output into GitHub secret: AZURE_CREDENTIALS
```

### GCP
```bash
gsutil mb -l asia-south1 gs://cloudops-ai-tfstate-<your-project-id>
gsutil versioning set on gs://cloudops-ai-tfstate-<your-project-id>

gcloud iam service-accounts create cloudops-ai-gha
gcloud projects add-iam-policy-binding <project-id> \
  --member="serviceAccount:cloudops-ai-gha@<project-id>.iam.gserviceaccount.com" \
  --role="roles/editor"
gcloud iam service-accounts keys create gcp-key.json \
  --iam-account=cloudops-ai-gha@<project-id>.iam.gserviceaccount.com
```
GitHub secrets to add:
- `GCP_CREDENTIALS` — contents of `gcp-key.json`
- `GCP_PROJECT_ID` — your project id (e.g. `cloudops-ai-forge`)
- `GCP_TFSTATE_BUCKET` — the bucket name from `gsutil mb` above

### AWS
```bash
aws s3api create-bucket --bucket cloudops-ai-tfstate-aws --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
aws s3api put-bucket-versioning --bucket cloudops-ai-tfstate-aws --versioning-configuration Status=Enabled
```
Set up an OIDC-based IAM role for GitHub Actions (no long-lived keys) —
follow AWS's "configure-aws-credentials" GitHub OIDC guide — and add the
role ARN as GitHub secret `AWS_ROLE_ARN`.

## Running it

**Actions → CloudOps-AI Multi-Cloud Pipeline → Run workflow**, pick:

| input | options |
|---|---|
| `cloud_provider` | `azure` / `gcp` / `aws` |
| `action` | `apply` (build/update everything) · `deploy-only` (skip infra, just rebuild+redeploy the app) · `destroy` (tear down that cloud's resources) |
| `app_source` | git URL with a Dockerfile at root, or `skip` |
| `image_tag` | defaults to `latest` |

Each cloud's state is independent — destroying `azure` doesn't touch `gcp` or
`aws`, and vice versa. You can even run two clouds side by side for a
multi-cloud demo.

## Testing destroy

Run the workflow with the `cloud_provider` you want to tear down and
`action = destroy`. It runs `terraform destroy -auto-approve` against that
cloud's remote state only.
