# pid=$(mktemp)
# echo "temp = $pid"
# (
#     set -x
#     sleep 5 &
#     echo "$!" > $pid 
# ) 
# pid=$(cat $pid)
# echo "pid=$pid"
# wait $pid
read a
# while ps -p $pid ; do sleep 1; done 


# while ps -p $! 1>/dev/null; do echo -n '.'; sleep 1; done
# ps -p "$!"