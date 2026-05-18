#!/bin/bash

echo "==========================================="
echo " Kubernetes Preflight Checker"
echo "==========================================="
echo ""

# ---------------------------------------------------

# Funções

# ---------------------------------------------------

ok() {
echo -e "\e[32m✅ $1\e[0m"
}

fail() {
echo -e "\e[31m❌ $1\e[0m"
}

warn() {
echo -e "\e[33m⚠️  $1\e[0m"
}

# ---------------------------------------------------

# Swap

# ---------------------------------------------------

echo "---- SWAP ----"

if swapon --show | grep -q .; then
fail "Swap habilitado"
else
ok "Swap desabilitado"
fi

echo ""

# ---------------------------------------------------

# CPU/RAM

# ---------------------------------------------------

echo "---- HARDWARE ----"

CPU=$(nproc)
RAM=$(free -m | awk '/Mem:/ {print $2}')

echo "CPU: $CPU"
echo "RAM: ${RAM}MB"

if [ "$CPU" -ge 2 ]; then
ok "CPU suficiente"
else
warn "Menos de 2 CPUs"
fi

if [ "$RAM" -ge 2000 ]; then
ok "RAM suficiente"
else
warn "Menos de 2GB RAM"
fi

echo ""

# ---------------------------------------------------

# Kernel modules

# ---------------------------------------------------

echo "---- KERNEL MODULES ----"

if lsmod | grep -q br_netfilter; then
ok "br_netfilter carregado"
else
fail "br_netfilter NÃO carregado"
fi

if lsmod | grep -q overlay; then
ok "overlay carregado"
else
fail "overlay NÃO carregado"
fi

echo ""

# ---------------------------------------------------

# Sysctl

# ---------------------------------------------------

echo "---- SYSCTL ----"

IPF=$(sysctl -n net.ipv4.ip_forward)

if [ "$IPF" = "1" ]; then
ok "ip_forward habilitado"
else
fail "ip_forward desabilitado"
fi

echo ""

# ---------------------------------------------------

# Containerd

# ---------------------------------------------------

echo "---- CONTAINERD ----"

if command -v containerd >/dev/null 2>&1; then
ok "containerd instalado"
else
fail "containerd NÃO instalado"
fi

if systemctl is-active --quiet containerd; then
ok "containerd rodando"
else
fail "containerd parado"
fi

echo ""

# ---------------------------------------------------

# SystemdCgroup

# ---------------------------------------------------

echo "---- CGROUP DRIVER ----"

if grep -q "SystemdCgroup = true" /etc/containerd/config.toml 2>/dev/null; then
ok "SystemdCgroup=true"
else
fail "SystemdCgroup=false ou ausente"
fi

echo ""

# ---------------------------------------------------

# CRI

# ---------------------------------------------------

echo "---- CRI ----"

if grep -q "disabled_plugins.*cri" /etc/containerd/config.toml 2>/dev/null; then
fail "CRI desabilitado"
else
ok "CRI habilitado"
fi

echo ""

# ---------------------------------------------------

# Kubernetes binaries

# ---------------------------------------------------

echo "---- KUBERNETES ----"

for bin in kubeadm kubelet kubectl; do
if command -v $bin >/dev/null 2>&1; then
VERSION=$($bin version --client 2>/dev/null | head -n 1)
ok "$bin instalado"
echo "   $VERSION"
else
fail "$bin NÃO instalado"
fi
done

echo ""

# ---------------------------------------------------

# Kubelet

# ---------------------------------------------------

echo "---- KUBELET ----"

if systemctl is-enabled --quiet kubelet; then
ok "kubelet habilitado"
else
warn "kubelet não habilitado"
fi

if systemctl is-active --quiet kubelet; then
ok "kubelet rodando"
else
warn "kubelet parado"
fi

echo ""

# ---------------------------------------------------

# Cgroup version

# ---------------------------------------------------

echo "---- CGROUP VERSION ----"

CGROUP=$(stat -fc %T /sys/fs/cgroup/)

echo "Detectado: $CGROUP"

if [ "$CGROUP" = "cgroup2fs" ]; then
ok "cgroup v2"
else
warn "cgroup v1"
fi

echo ""

# ---------------------------------------------------

# Kubelet extra args

# ---------------------------------------------------

echo "---- KUBELET EXTRA ARGS ----"

if grep -q "fail-cgroup-v1=false" /etc/default/kubelet 2>/dev/null; then
ok "fail-cgroup-v1=false configurado"
else
warn "flag fail-cgroup-v1=false ausente"
fi

echo ""

# ---------------------------------------------------

# Portas importantes

# ---------------------------------------------------

echo "---- PORTAS ----"

PORTS=(6443 10250)

for p in "${PORTS[@]}"; do
if ss -tulnp | grep -q ":$p "; then
ok "Porta $p em uso"
else
warn "Porta $p não detectada"
fi
done

echo ""

# ---------------------------------------------------

# DNS

# ---------------------------------------------------

echo "---- DNS ----"

if ping -c 1 google.com >/dev/null 2>&1; then
ok "Internet funcionando"
else
fail "Sem acesso DNS/internet"
fi

echo ""

# ---------------------------------------------------

# Final

# ---------------------------------------------------

echo "==========================================="
echo " Verificação concluída"
echo "==========================================="
echo ""

echo "Se houver ❌ corrija antes do kubeadm init/join"
echo ""
