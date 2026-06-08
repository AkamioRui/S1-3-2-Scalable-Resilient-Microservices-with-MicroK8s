### enable registry     
   

### push image 
podman images | grep 'localhost:32000/' | awk '{print $1":"$2}' | xargs -I {image} sh -c 'set -x;podman push --tls-verify=false {image}'
if [ $? -eq 0 ] ; then echo -e "=============== PUSHED ===============\n"; else echo -e "=============== PUSHED error ===============\n"; fi

### ============== verify image in repository ===============
images_in_repository(){
    curl -s localhost:32000/v2/_catalog | \
    sed -nE 's/^.*\[(.*)\].*$/\1/p' | tr -d '"' | tr ',' '\n' | \
    xargs -I {} curl localhost:32000/v2/{}/tags/list
    echo -e "=============== images in repository ===============\n"
}
images_in_repository

### ============== verify image in manifest ===============
images_in_manifest(){
    ls k8s_manifest | xargs -I {} sh -c ' echo "image from k8s_manifest/{}\n" ; cat k8s_manifest/{} ' | grep image | grep -P --color=always 'localhost:32000|$'
}
images_in_manifest


## deleting from registry
# kubectl exec -it registry-746ff6c6fc-tht6s -n container-registry -- bin/registry garbage-collect /etc/docker/registry/config.yml