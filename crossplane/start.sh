#!/bin/bash
while getopts ":p:c:" opt; do
  case ${opt} in
      p) project=${OPTARG} ;;
      c) credentials=${OPTARG} ;;
      *) echo "Invalid option: $OPTARG" ;;
  esac
done
shift $((OPTIND -1))

if [ -z ${project+x} ]; then
  echo "Project is not set, please use the -p command line option followed by the name of your project"
  exit 1
fi

if [ -z ${credentials+x} ]; then
  echo "Path to credentials JSON file not set, please use the -c command line option followed by the path to your json credentials file"
  exit 1
fi

CROSSPLANE_VERSION=0.13.0-rc.63.gfe3c371
CLOUDSDK_CORE_PROJECT=${project}
export GOOGLE_CLOUD_KEYFILE_JSON=${credentials}
GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_CLOUD_KEYFILE_JSON}

echo "Authenticating with credentials file: ${GOOGLE_CLOUD_KEYFILE_JSON}"

required_services=(compute.googleapis.com container.googleapis.com cloudresourcemanager.googleapis.com sqladmin.googleapis.com pubsub.googleapis.com)

for service in "${required_services[@]}"; do
  if gcloud services list | grep "${service}" 2>&1 > /dev/null; then
    echo "API ${service} already enabled"
  else
    echo "Enabling API ${service}"
    gcloud services enable "${service}"
  fi
done

echo "Checking for required tools"
required_tools=(terraform helm)

for tool in "${required_tools[@]}"; do
    if ! command -v ${tool} 2>&1 > /dev/null; then
      echo "Tool: ${tool} was not found, if installed, please make sure it is in your path"
      exit 1
    fi
done
echo "All required tools are available in the system"

pushd terraform
echo "Checking to terraform.tfvars file"
if [[ ! -f ./terraform.tfvars ]]; then
  echo "File terraform.tfvars does not exist, please create the file with the necessary terraform variable values to proceed"
  exit 1
fi
terraform init
terraform apply -auto-approve
popd

echo "Getting credentials for newly created cluster"
gcloud container clusters get-credentials murillodigital-crossplane --region us-east1

echo "Adding the Crosplane Helm Chart repository and installing it on our new kubernetes cluster."
helm repo add crossplane-master https://charts.crossplane.io/master/
helm install crosplane --namespace crossplane-system crossplane-master/crossplane --version ${CROSSPLANE_VERSION} --devel --create-namespace

echo "Install kubectl crossplane cli commands - this will require sudo rights"
curl -sL https://raw.githubusercontent.com/crossplane/crossplane-cli/master/bootstrap.sh | sudo bash

PROVIDER_PACKAGE=crossplane/provider-gcp:v0.11.0
PROVIDER_NAME=provider-gcp

echo "Installing GCP package for crossplane - this installs GCP resource CRDs"
kubectl crossplane package install --cluster --namespace crossplane-system ${PROVIDER_PACKAGE} ${PROVIDER_NAME}