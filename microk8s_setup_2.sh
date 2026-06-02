microk8s enable registry
# deployment.apps/registry                 
# deployment.apps/hostpath-provisioner     
# service/registry     
curl http://localhost:32000/v2/_catalog

microk8s enable ingress
## kubectl get all -A. differs in namespace ingress
