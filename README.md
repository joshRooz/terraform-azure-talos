# Requirements
* Linux shell
* Git
* Azure CLI
* Terraform

# Clone the Repo
```sh
git clone https://github.com/joshRooz/terraform-azure-talos.git
```

# Download Talos Azure Image & talosctl
```sh
TALOS_VERSION="v0.11.5"

cd terraform-azure-talos
wget https://github.com/talos-systems/talos/releases/download/${TALOS_VERSION}/azure-amd64.tar.gz
wget https://github.com/talos-systems/talos/releases/download/${TALOS_VERSION}/sha256sum.txt
sudo curl -Lo /usr/local/bin/talosctl https://github.com/talos-systems/talos/releases/download/${TALOS_VERSION}/talosctl-$(uname -s | tr "[:upper:]" "[:lower:]")-amd64

egrep $(sha256sum azure-amd64.tar.gz) sha256sum.txt | wc -l
egrep $(sha256sum /usr/local/bin/talosctl) sha256sum.txt | wc -l

tar -zxvf azure-amd64.tar.gz  # decompresses 'disk.vhd' in v0.11.5
sudo chmod +x /usr/local/bin/talosctl
```

# Authenticate to Azure
az login --tenant <some-tenant-name-or-id>

# Azure Storage Account - SAS Keys
SAS Keys have been disabled in favour of RBAC with Storage Blob Data Contributor role assignment. However, the role assignment doesn't seem to be honoured right away and the VHD upload (`azurerm_storage_blob.this`) may fail with an `autorest/azure: error reponse cannot be parsed...` message. Try again after some time and the upload will succeed.

# Run Terraform

```sh
terraform init
terraform plan [-out=the-plan]
terraform apply -var=controlplane_admin=example-ctrl -var=controlplane_admin=example-wrkr [-auto-approve] [the-plan]
```

# Cluster Config
```sh
talosctl gen config talos-k8s-azure-tutorial https://$(terraform output lb_public_ip | sed 's|^.|| ; s|.$||'):6443
```

# Reference
* https://www.talos.dev/docs/v0.11/introduction/getting-started/
* https://www.talos.dev/docs/v0.11/cloud-platforms/azure