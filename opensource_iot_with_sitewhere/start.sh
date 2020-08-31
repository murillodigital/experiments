#!/bin/bash
git clone https://github.com/sitewhere/swctl.git
required_services=(compute.googleapis.com container.googleapis.com cloudresourcemanager.googleapis.com)
for service in "${required_services[@]}"; do
  gcloud services enable "${service}"
done
pushd swctl
go build
popd