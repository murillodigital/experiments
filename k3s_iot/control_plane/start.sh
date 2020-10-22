required_services=(compute.googleapis.com container.googleapis.com cloudresourcemanager.googleapis.com dns.googleapis.com)

for service in "${required_services[@]}"; do
  if gcloud services list | grep "${service}" 2>&1 > /dev/null; then
    echo "API ${service} already enabled"
  else
    echo "Enabling API ${service}"
    gcloud services enable "${service}"
  fi
done

helm repo add argo https://argoproj.github.io/argo-helm