# microk8s enable ingress


test_ingress(){
    microk8s kubectl get services -n ingress -o wide
    microk8s kubectl get pods -o wide
    read a

    http_nodeport=$(
        microk8s kubectl get all -n ingress | grep service | awk '{print $5}' |\
        grep -oP '(?<=80:).*?(?=/TCP)'  
    )
    curl_cmd="curl -s -H 'Host: api.myapp.com' http://localhost:$http_nodeport/hello.php"
    echo $curl_cmd
    read a

    echo "=============== curl result ==============="
    eval $curl_cmd 
    echo "=============== curl result end ==============="
    read a

    for ((i=0;i<10;i++)); do eval $curl_cmd | grep "gethostbyname" ;done

}
test_ingress

