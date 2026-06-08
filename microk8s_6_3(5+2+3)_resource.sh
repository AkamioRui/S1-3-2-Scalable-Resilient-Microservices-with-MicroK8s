############### global variable ###############
ingress_port=$(microk8s kubectl get services -n ingress | sed  -n '2p' | awk '{print $5}' | grep -oP '(?<=80:).*?(?=/TCP)')
echo "start"
read a

############### rescale pod ###############
echo "############### rescale pod ###############"
(set -x; microk8s kubectl scale deployment.apps/web-api-test-deploy --replicas=1)
### not consistant, just create a new terminal
# wt.exe -p "Ubuntu-26.04" -- wsl.exe -d "Ubuntu-26.04" bash -l -i -c "watch microk8s kubectl get all"
read a


############### sending one request ###############
echo -e "\n"
echo "############### sending one request ###############"
stress_cmd="curl -fsS -H 'Host: api-test.myapp.com' localhost:$ingress_port/stress.php"
echo $stress_cmd
echo "=============================="

bash -c " $stress_cmd ; echo -e \"\nexit code = \$?\"" &
curl_pid=$! 
while ps -p $curl_pid 1>/dev/null ; do echo -n '.'; sleep 1; done
read a





send_many_request(){
    # mycurl="curl -fsS -H 'Host: api.myapp.com' localhost:$ingress_port/stress.php"
    mycurl=$stress_cmd
    epoch=$1 # limit is 40
    echo "seq $epoch| xargs -I {} -P $epoch bash -c \"
        $mycurl > /dev/null 
        echo \"exitcode of {}=\$? \" > /tmp/out.{}
    \""

    seq $epoch| xargs -I {} -P $epoch bash -c "
        echo -n '' >/tmp/out.{}
        $mycurl >/dev/null 2>>/tmp/out.{}
        echo \"exitcode of {}=\$? \" >>/tmp/out.{}
    " &

    pid=$!;
    while ps -p $pid >/dev/null; do echo -n '.'; sleep 1; done
    echo ''
    seq $epoch| xargs -I {} cat /tmp/out.{}
    
}
################ overload 1 pod ###############
echo -e "\n"
echo "################ overload 1 pod ###############"
send_many_request 40
read a

############### rescale pod ###############
echo -e "\n"
echo "############### rescale pod ###############"
(
    set -x;
    microk8s kubectl scale deployment.apps/web-api-test-deploy --replicas=3;
)
read a

################ overload 3 ###############
echo -e "\n"
echo "################ overload 3 pod ###############"
send_many_request 40

