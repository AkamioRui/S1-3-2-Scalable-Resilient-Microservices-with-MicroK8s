repo=https://github.com/AkamioRui/S1-3-2-Scalable-Resilient-Microservices-with-MicroK8s.git
images_folder=./images

for image in "web-api" "web-server" "web-scrapper" "database" "analyzer"; do
    git clone -b $image $repo $images_folder/$image    
done
