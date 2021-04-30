#!/bin/bash
# 2020.1.18 Mon
#    使用標準的 baseline snapshot，安裝 v1.20.2
# 2020.1.9 Sat
#    使用標準的 baseline snapshot，安裝 v1.20.1
# 2021.1.9 Sat
#    yaml 檔案搬家到 rh8ex294
yum install sshpass -y

# 2021.1.9 校時
/usr/sbin/ntpdate -b -u time.stdtime.gov.tw
sshpass -p container ssh -p 22 root@node1 "/usr/sbin/ntpdate -b -u time.stdtime.gov.tw"
sshpass -p container ssh -p 22 root@node2 "/usr/sbin/ntpdate -b -u time.stdtime.gov.tw"

#排程校時
echo '* * * * * /usr/sbin/ntpdate -b -u time.stdtime.gov.tw > /dev/null 2>&1' > /var/spool/cron/root
sshpass -p container scp /var/spool/cron/root root@node1:/var/spool/cron/root
sshpass -p container scp /var/spool/cron/root root@node2:/var/spool/cron/root

# 停用更新
systemctl stop packagekit && systemctl disable packagekit && systemctl status packagekit
sshpass -p container ssh -p 22 root@node1 "systemctl stop packagekit && systemctl disable packagekit && systemctl status packagekit"
sshpass -p container ssh -p 22 root@node2 "systemctl stop packagekit && systemctl disable packagekit && systemctl status packagekit"

yum install docker -y
sshpass -p container ssh -p 22 root@node1 "yum install docker -y"
sshpass -p container ssh -p 22 root@node2 "yum install docker -y"


systemctl enable docker && systemctl start docker && systemctl status docker
sshpass -p container ssh -p 22 root@node1 "systemctl enable docker && systemctl start docker && systemctl status docker"
sshpass -p container ssh -p 22 root@node2 "systemctl enable docker && systemctl start docker && systemctl status docker"

yum install bash-completion -y
sshpass -p container ssh -p 22 root@node1 "yum install bash-completion -y"
sshpass -p container ssh -p 22 root@node2 "yum install bash-completion -y"


free -m
swapoff /dev/mapper/centos-swap
free -m
sed -i 's/^\/dev\/mapper\/centos-swap/#&/g' /etc/fstab
cat /etc/fstab
sshpass -p container ssh -p 22 root@node1 "swapoff /dev/mapper/centos-swap"
sshpass -p container ssh -p 22 root@node1 "sed -i 's/^\/dev\/mapper\/centos-swap/#&/g' /etc/fstab"
sshpass -p container ssh -p 22 root@node1 "free -m"
sshpass -p container ssh -p 22 root@node2 "swapoff /dev/mapper/centos-swap"
sshpass -p container ssh -p 22 root@node2 "sed -i 's/^\/dev\/mapper\/centos-swap/#&/g' /etc/fstab"
sshpass -p container ssh -p 22 root@node2 "free -m"


cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
sshpass -p container scp /etc/sysctl.d/k8s.conf root@node1:/etc/sysctl.d/k8s.conf
sshpass -p container ssh -p 22 root@node1 "sysctl --system"
sshpass -p container scp /etc/sysctl.d/k8s.conf root@node2:/etc/sysctl.d/k8s.conf
sshpass -p container ssh -p 22 root@node2 "sysctl --system"


yum install -y ipvsadm conntrack sysstat curl
sshpass -p container ssh -p 22 root@node1 "yum install -y ipvsadm conntrack sysstat curl"
sshpass -p container ssh -p 22 root@node2 "yum install -y ipvsadm conntrack sysstat curl"


modprobe br_netfilter && modprobe ip_vs
sshpass -p container ssh -p 22 root@node1 "modprobe br_netfilter && modprobe ip_vs"
sshpass -p container ssh -p 22 root@node2 "modprobe br_netfilter && modprobe ip_vs"


cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck
systemctl enable kubelet && systemctl start kubelet && systemctl status kubelet
sshpass -p container scp /etc/yum.repos.d/kubernetes.repo root@node1:/etc/yum.repos.d/kubernetes.repo
sshpass -p container ssh -p 22 root@node1 "yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck"
sshpass -p container ssh -p 22 root@node1 "systemctl enable kubelet && systemctl start kubelet && systemctl status kubelet"
sshpass -p container scp /etc/yum.repos.d/kubernetes.repo root@node2:/etc/yum.repos.d/kubernetes.repo
sshpass -p container ssh -p 22 root@node2 "yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck"
sshpass -p container ssh -p 22 root@node2 "systemctl enable kubelet && systemctl start kubelet && systemctl status kubelet"



#(master)【需要一段時間】
# 參考 DO380，P.10
# service network【openshift_portal_net】 預設是 /16，172.30.0.0/16
#   因為 docker0 網卡使用 172.17.0.0/16，要避開這段
# pod network【osm_cluster_network_cidr】 預設是 /14，10.128.0.0/14
kubeadm init --service-cidr 10.96.0.0/12 --pod-network-cidr 172.16.0.0/16 --apiserver-advertise-address 0.0.0.0


mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get nodes
kubectl get nodes -o wide


#(node1+node2)
SHA256=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | awk '{ print $2}')
echo $SHA256
TOKEN=$(kubeadm token list | tail -n +2 | awk '{ print $1 }')
echo $TOKEN

sshpass -p container ssh -p 22 root@node1 "kubeadm join 192.168.66.10:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$SHA256"
sshpass -p container ssh -p 22 root@node2 "kubeadm join 192.168.66.10:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$SHA256"
#sshpass -p container ssh -p 22 root@node2 "kubeadm join 192.168.66.10:6443 --token ibeg1q.7nsyqyj876p7zb2l --discovery-token-ca-cert-hash sha256:2287348387c23803a64718f4509134e1ea83f2c1342c36d37c5a9e37893ea2f6"

kubectl get nodes


#(master)
#wget https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml

#vi kube-flannel.yml
##########################
#...
#  net-conf.json: |
#    {
#      "Network": "172.16.0.0/16",
#      "Backend": {
#        "Type": "vxlan"
#      }
#
##########################

#wget https://raw.githubusercontent.com/coreos/flannel/32a765fd19ba45b387fdc5e3812c41fff47cfd55/Documentation/kube-flannel.yml
# 改 127行的 pod network
# 在 108行之後，加入一行
#    105 data:
#    106   cni-conf.json: |
#    107     {
#    108       "name": "cbr0",
#    109       "plugins": [
#    110         {
#    111           "type": "flannel",


#wget http://rh7lab.uuu.com.tw/download/Docker/kube-flannel.yml
wget https://rh8ex294.uuu.com.tw/download/Docker/kube-flannel.yml

kubectl apply -f kube-flannel.yml

kubectl get pods --all-namespaces
kubectl get nodes
kubectl get nodes -o wide


#(master+node1+node2)
source <(kubectl completion bash)
sshpass -p container ssh -p 22 root@node1 "source <(kubectl completion bash)"
sshpass -p container ssh -p 22 root@node2 "source <(kubectl completion bash)"



kubectl get pods --all-namespaces
kubectl get nodes
kubectl get nodes -o wide
echo "Wait 30 seconds for get Ready..."
kubectl get pods --all-namespaces
kubectl get nodes
kubectl get nodes -o wide


