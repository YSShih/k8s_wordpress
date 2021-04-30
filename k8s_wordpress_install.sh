#!bin/bash
mkdir -p /data/db

mkdir -p /data/wordpress

sshpass -p container ssh -p 22 root@node1 "mkdir -p /data/"
sshpass -p container ssh -p 22 root@node2 "mkdir -p /data/"


yum install nfs-utils -y

sshpass -p container ssh -p 22 root@node1 "yum install nfs-utils -y"
sshpass -p container ssh -p 22 root@node2 "yum install nfs-utils -y"


cat <<EOF > /etc/exports
/data *(rw,no_root_squash)
EOF

systemctl start nfs && systemctl enable nfs && systemctl status nfs

systemctl start nfs-server && systemctl enable nfs-server && systemctl status nfs-server


sshpass -p container ssh -p 22 root@node1 "mkdir /data"
sshpass -p container ssh -p 22 root@node1 "mount -t nfs master:/data /data"

sshpass -p container ssh -p 22 root@node2 "mkdir /data"
sshpass -p container ssh -p 22 root@node2 "mount -t nfs master:/data /data"

sshpass -p container ssh -p 22 root@node1 "df -Th |grep nfs"
sshpass -p container ssh -p 22 root@node2 "df -Th |grep nfs"

cp /etc/fstab /tmp/fstab
echo "master:/data /data nfs default 0 0">> /tmp/fstab
cat /tmp/fstab

sshpass -p container scp /tmp/fstab root@node1:/etc/fstab
sshpass -p container scp /tmp/fstab root@node2:/etc/fstab


kubectl create configmap mydb-env --from-literal=MYSQL_ROOT_PASSWORD=container --from-literal=TZ="Asia/Taipei"

kubectl get configmaps

kubectl describe configmaps mydb-env

kubectl create secret generic mysql-pass --from-literal=password=container

kubectl get secret

kubectl describe secret mysql-pass

kubectl apply -f volumes.yaml

kubectl get pv

kubectl apply -f mysql-deployment.yaml

kubectl get pods

kubectl apply -f wordpress-deployment.yaml

kubectl get pods

kubectl get services
