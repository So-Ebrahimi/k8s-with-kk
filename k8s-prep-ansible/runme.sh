apt install ansible-core , sshpass 
ansible-galaxy collection install community.general
export ANSIBLE_HOST_KEY_CHECKING=False 
ansible all -i inventory.ini -m ping -k -K
ansible-playbook -i inventory.ini prepare-k8s-nodes.yml -k -K
ansible k8s_nodes -i inventory.ini -m shell -a "hostname && free -h && lsmod | egrep 'overlay|br_netfilter|ip_vs' && sysctl net.ipv4.ip_forward"
