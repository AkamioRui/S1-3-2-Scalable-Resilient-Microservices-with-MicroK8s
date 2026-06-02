repo=https://github.com/AkamioRui/S1-3-2-Scalable-Resilient-Microservices-with-MicroK8s.git
images_folder=./images
images= web-api web-server web-scrapper database analyzer
for $image in $images; do
    git clone -b $image $repo $images_folder/$image    
end;

# git clone -b web-api $repo $images_folder/web-api
# git clone -b web-server $repo $images_folder/web-server
# git clone -b web-scrapper $repo $images_folder/web-scrapper
# git clone -b database $repo $images_folder/database
# git clone -b analyzer $repo $images_folder/analyzer