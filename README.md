# EC2-Managed-Kubernetes-With-Kubeadm

##Do the initial setup with the terraform to launch the EC2 instances. The terraform code will create the below listed resources 
VPC
Subnet
Internet Gateway
Attach Internet Gateway to the VPC
Route table
Security Group
associate the EPI to the instances 
Run the initial package script across all instacnes. Package Script Source: https://github.com/networknuts/kubernetes/blob/master/scripts/packages-kubernetes-1.30
You should store the above script in scripts folder named init-script.sh
C:.
├───main.tf
└───scripts

AWS provider should be already configured. You can run some sample commands like "aws s3 ls" to see if you can talk to your aws accountr via cli. 

##Initaite terraform
terraform init

##Run validate and plan for your review(optional)
terraform validate
terraform plan

##Deploy the resources
terraform apply

##Sample Output
Apply complete! Resources: 16 added, 0 changed, 0 destroyed.
Outputs:
instance_info = [
  {
    "name" = "Master"
    "private_ip" = "10.5.1.95"
    "public_ip" = "18.204.187.106"
  },
  {
    "name" = "Node-1"
    "private_ip" = "10.5.1.51"
    "public_ip" = "13.219.116.105"
  },
  {
    "name" = "Node-2"
    "private_ip" = "10.5.1.30"
    "public_ip" = "35.169.9.102"
  },
]

##Login to the master instance
##Pull images before initializing the cluster
sudo kubeadm config images pull

##Initialize the cluster. private-cidr should be a cidr which is not being used in this network
sudo kubeadm init --apiserver-advertise-address <master-private-ip> --pod-network-cidr <private-cidr>

##Post that run these commands to update the kube config
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

##Create a yaml file to create the calico network
##Source: https://github.com/networknuts/kubernetes/blob/master/scripts/calico.yaml
kubectl apply -f network.yaml

##Check the pod status
kubectl -n kube-system get pods

##Get the node details
kubectl get nodes

##Once the control-plane is ready. You can join the worker nodes
##Generate the command with token to join the nodes. Run those commands on the worker nodes
kubeadm token create --print-join-command
