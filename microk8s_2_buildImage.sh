# creating and pushing the image
(
cd images 
podman-compose build;
if [ $? -eq 0 ]; then
    echo -e "\n=============== build completed ===============\n";
else 
    echo -e "\n=============== build failed ===============\n";
fi
)


# # verifying image function
verify_podman(){
    (
        cd deleteme
        podman-compose down --timeout 1;
        podman-compose up -d;
        podman images && podman ps -a;
        curl localhost:8000/hello.php
    )
}
close_podman(){
    (
        cd deleteme
        podman-compose down --timeout 1;
    )
}





