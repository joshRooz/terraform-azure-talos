# Requirements
* Linux shell
* Git
* Azure CLI
* Terraform

# Clone the Repo
```sh
git clone <this-repo>
```

# Download Talos Azure Image & talosctl
```sh
cd <cloned-repo-working-dir>
wget https://github.com/talos-systems/talos/releases/download/v0.11.5/azure-amd64.tar.gz
wget https://github.com/talos-systems/talos/releases/download/v0.11.5/sha256sum.txt
sudo curl -Lo /usr/local/bin/talosctl https://github.com/talos-systems/talos/releases/v0.11.5/download/talosctl-$(uname -s | tr "[:upper:]" "[:lower:]")-amd64

egrep $(sha256sum azure-amd64.tar.gz /usr/local/bin/talosctl) sha256sum.txt | wc -l

tar -zxvf azure-amd64.tar.gz  # decompresses 'disk.vhd' in v0.11.5
sudo chmod +x /usr/local/bin/talosctl
```

# Authenticate to Azure
az login --tenant <some-tenant-name-or-id>

# Run Terraform
```sh
terraform init
terraform plan [-out=the-plan]
terraform apply -var=controlplane_admin=example-ctrl -var=controlplane_admin=example-wrkr [-auto-approve the-plan]
```

# Cluster Config
```sh
talosctl gen config talos-k8s-azure-tutorial https://$(terraform output lb_public_ip | sed 's|^.|| ; s|.$||'):6443
```

# Reference
* https://www.talos.dev/docs/v0.11/cloud-platforms/azure