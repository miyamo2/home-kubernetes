# home-kubernetes

Foundations of My Own Home Kubernetes

## Prerequirements

1. yq is installed
2. Setup Control Plane
```sh
export VIP=<virtual ip>
curl -sfL https://get.k3s.io | K3S_TOKEN="<k3s install token>" \
K3S_NODE_NAME=<node name here> \
sh -s - server --flannel-backend=none --tls-san=$VIP \
--disable-network-policy --disable-kube-proxy --disable "servicelb" --disable "traefik" \
--cluster-init \
--write-kubeconfig-mode 644
```
3. Prepare kube-vip
```sh 
sudo sh -c "curl https://kube-vip.io/manifests/rbac.yaml > /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml"

export INTERFACE=eth0
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
alias kube-vip="sudo ctr image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; sudo ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"

kube-vip manifest pod \
    --interface $INTERFACE \
    --address $VIP \
    --controlplane \
    --services \
    --arp \
    --leaderElection | sudo sh -c "yq '.metadata.name = \"kube-vip-1\" | .spec.volumes[0].hostPath.path = \"/etc/rancher/k3s/k3s.yaml\"' > /var/lib/rancher/k3s/server/manifests/kube-vip-1.yaml"

sudo sh -c "yq -i '.clusters[0].cluster.server = \"https://<virtual ip>:6443\"' /etc/rancher/k3s/k3s.yaml"
```

4. Prepare the second after control planes

```sh
export VIP=<virtual ip>

curl -sfL https://get.k3s.io | K3S_TOKEN="<k3s install token>" \
K3S_NODE_NAME=<node name here> \
sh -s - server --flannel-backend=none --tls-san=<> --tls-san=<virtual ip> --tls-san=127.0.0.1 \
--disable-network-policy --disable "servicelb" --disable "traefik" --disable "local-storage" --disable "metrics-server" \
--server <uri for the node in step2> \
--write-kubeconfig-mode 644

export INTERFACE=eth0
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
alias kube-vip="sudo ctr image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; sudo ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"

kube-vip manifest pod \
    --interface $INTERFACE \
    --address $VIP \
    --controlplane \
    --services \
    --arp \
    --leaderElection | sudo sh -c "yq '.metadata.name = \"kube-vip-<N>\" | .spec.volumes[0].hostPath.path = \"/etc/rancher/k3s/k3s.yaml\"' > /var/lib/rancher/k3s/server/manifests/kube-vip-1.yaml"

sudo sh -c "yq -i '.clusters[0].cluster.server = \"https://<virtual ip>:6443\"' /etc/rancher/k3s/k3s.yaml"
```
