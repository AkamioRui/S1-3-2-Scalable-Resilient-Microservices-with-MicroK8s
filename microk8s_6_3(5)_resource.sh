############### global variable ###############
ingress_port=$(microk8s kubectl get services -n ingress | sed  -n '2p' | awk '{print $5}' | grep -oP '(?<=80:).*?(?=/TCP)')

############### rescale pod ###############
# (set -x; microk8s kubectl scale deployment.apps/web-api-test-deploy --replicas=1)
# wt.exe -p "Ubuntu-26.04" -- wsl.exe -d "Ubuntu-26.04" bash -l -i -c "watch microk8s kubectl get all"

############### sending one request ###############
# stress_cmd="curl -fs -H 'Host: api.myapp.com' localhost:$ingress_port/stress.php"
# echo "=============================="
# echo $stress_cmd
# read a

# bash -c " curl -fs -H 'Host: api.myapp.com' localhost:$ingress_port/stress.php >/dev/null ; echo \$?" &
# curl_pid=$! 
# while ps -p $curl_pid 1>/dev/null ; do echo -n '.'; sleep 1; done
# read a




############### sending multiple request ###############
mycurl="curl -fsS -H 'Host: api.myapp.com' localhost:$ingress_port/stress.php"
epoch=20 # limit is 40
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
read a

# echo "done"
# read a
# eval $mycurl &
# pid=$!
# while ps -p $! 1>/dev/null; do echo -n "."; sleep 1; done
# read a



### potential metric
# microk8s enable metrics-server
# kubectl top pod <pod-name>



########
# watch microk8s kubectl get all &
# WATCH_PID=$!
# trap "kill $WATCH_PID" INT
# wait $WATCH_PID