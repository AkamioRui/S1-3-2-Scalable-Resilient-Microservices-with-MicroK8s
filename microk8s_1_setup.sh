sudo snap install microk8s --classic
sudo usermod -a -G microk8s ruima
sudo reboot

microk8s enable registry  
microk8s enable ingress