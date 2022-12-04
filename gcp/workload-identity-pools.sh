### Setting up Workload Identity Federation
# https://github.com/google-github-actions/auth#setup

## env
project="vntg-gw-dev-324106"
project_number=`gcloud projects describe $project --format='value(projectNumber)'`

# bucket_for_github
bucket_for_github="vntg-gw-tm-operation-dev"


## create service account 
service_account="deploy-to-cloud-storage"
service_account_full_name="$service_account@$project.iam.gserviceaccount.com"

gcloud iam service-accounts create $service_account \
    --description="deploy to cloud storage" \
    --display-name="deploy to cloud storage" \
    --project=$project

# Grant the Google Cloud Service Account permissions to access Google Cloud resources.
gsutil iam ch serviceAccount:$service_account@$project.iam.gserviceaccount.com:objectAdmin gs://$bucket_for_github


##
#export PROJECT_ID="vntg-gw-dev-324106"

# Enable the IAM Credentials API:
gcloud services enable iamcredentials.googleapis.com 


pool_name="dev-pools"

# Create a Workload Identity Pool
gcloud iam workload-identity-pools create "$pool_name" \
  --location="global" \
  --display-name="$pool_name"

# Get the full ID of the Workload Identity Pool:
#gcloud iam workload-identity-pools describe "$pool_name" \
#  --location="global" \
#  --format="value(name)"

# Save this value as an environment variable
export WORKLOAD_IDENTITY_POOL_ID="projects/$project_number/locations/global/workloadIdentityPools/$pool_name"

# Create a Workload Identity Provider in that pool:
provider_name="github-provider"

gcloud iam workload-identity-pools providers create-oidc "$provider_name" \
  --location="global" \
  --workload-identity-pool="$pool_name" \
  --display-name="github provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"
  
# Allow authentications from the Workload Identity Provider originating from your repository to impersonate the Service Account created above:
export REPO="VntgCorp/gcp_operations"

gcloud iam service-accounts add-iam-policy-binding "$service_account_full_name" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"

# Extract the Workload Identity Provider resource name
# Use this value as the workload_identity_provider value in your GitHub Actions YAML.
#gcloud iam workload-identity-pools providers describe "$provider_name" \
#  --location="global" \
#  --workload-identity-pool="$pool_name" \
#  --format='value(name)'
workload_identity_provider="projects/$project_number/locations/global/workloadIdentityPools/$pool_name/providers/$provider_name"

echo "workload_identity_provider: '$workload_identity_provider'"
echo "service_account: '$service_account_full_name'"
