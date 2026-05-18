#!/bin/bash
set -e

echo "======================================"
echo " Kubernetes 1.35 Installer"
echo "======================================"

# =========================
# 1. BASE SYSTEM
# =========================
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gpg

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# =========================
# 2. KERNEL MODULES
# =========================
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# =========================
# 3. CONTAINERD (CRI)
# =========================
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# =========================
# 4. KUBERNETES REPOSITORY (1.35)
# =========================
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | \
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

# =========================
# 5. INSTALL KUBERNETES
# =========================
sudo apt install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

# =========================
# 6. KUBELET CONFIG (cgroup compat)
# =========================
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--fail-cgroup-v1=false
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now kubelet
sudo systemctl restart kubelet

# =========================
# 7. SSH (LAB OPTION)
# =========================
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# =========================
# 8. FINAL CHECK
# =========================
echo ""
echo "======================================"
echo " READY FOR KUBERNETES 1.35"
echo "======================================"
echo ""

kubectl version --client || true
echo ""
hostname -I

echo ""
echo "NEXT:"
echo "MASTER: kubeadm init"
echo "WORKER: kubeadm join <token>"
echo ""
