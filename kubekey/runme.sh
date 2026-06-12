curl -sfL https://get-kk.kubesphere.io | SKIP_WEB_INSTALLER=true SKIP_PACKAGE=true sh -
chmod +x kk
sudo ./kk create cluster -i inventory.yaml -c config.yaml

## on mastre 
sudo ctr -n k8s.io image pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.10.1
sudo ctr -n k8s.io image tag --force \
  registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.10.1 \
  registry.k8s.io/pause:v1.34.0

sudo ctr -n k8s.io image pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.34.0
sudo ctr -n k8s.io image tag --force \
  registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.34.0 \
  registry.k8s.io/kube-apiserver:v1.34.0

sudo ctr -n k8s.io image pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.34.0
sudo ctr -n k8s.io image tag --force \
  registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.34.0 \
  registry.k8s.io/kube-controller-manager:v1.34.0

sudo ctr -n k8s.io image pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.34.0
sudo ctr -n k8s.io image tag --force \
  registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.34.0 \
  registry.k8s.io/kube-scheduler:v1.34.0
