### apply manifest
(
cd k8s_manifest/

ls | xargs -I {file} sh -c 'set -x; microk8s kubectl apply -f {file}';
echo -e "=============== applied all ===============\n"
microk8s kubectl get all;
microk8s kubectl get pod -o wide;

)

test_web_LB(){
    kubectl get services -o wide
    kubectl get pods -o wide
    IP=$(kubectl get all| grep 'service/web-api-test-svc' | awk '{print $3}')

    cmd= "curl -s http://$IP/hello.php | grep 'gethostbyname='"
    echo "running $cmd"
    for ((i = 0; i <  100; i++)); do eval $cmd; done
}

## deleting from registry
# kubectl exec -it registry-746ff6c6fc-tht6s -n container-registry -- bin/registry garbage-collect /etc/docker/registry/config.yml