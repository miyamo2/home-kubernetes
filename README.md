# home-kubernetes

Foundations of My Own Home Kubernetes

## Prerequirements

1. containerd is installed
2. Prepare kube-vip manifest
```sh
sudo mkdir -p /var/lib/rancher/k3s/server/manifests/
sudo sh -c "curl https://kube-vip.io/manifests/rbac.yaml > /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml"

export VIP=<virtual IP to launch>
export INTERFACE=<Network interface, such as eth0>
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
alias kube-vip="sudo ctr image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; sudo ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"
kube-vip manifest daemonset \
    --interface $INTERFACE \
    --address $VIP \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --arp \
    --leaderElection | tee vip-daemonset.yaml
```
3. Setup Control Plane
```sh
curl -sfL https://get.k3s.io | K3S_TOKEN="<k3s install token>" \
K3S_NODE_NAME=<node name here> \
sh -s - server --flannel-backend=none --tls-san=$VIP \
--disable-network-policy --disable-kube-proxy --disable "servicelb" --disable "traefik" --disable "metrics-server" \
--cluster-init \
--write-kubeconfig-mode 644
```
4. (Optional) For an HA setup
```sh
curl -sfL https://get.k3s.io | K3S_TOKEN="<k3s install token>" \
K3S_NODE_NAME=<node name here> \
sh -s - server --flannel-backend=none \
--disable-network-policy --disable-kube-proxy --disable "servicelb" --disable "traefik" --disable "metrics-server" \
--server <local address from Step 3>
```