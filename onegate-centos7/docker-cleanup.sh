docker rm $(docker ps -a | grep "Exit" | awk '{print $1}')
docker rmi $(docker image list | grep "^<none>" | awk '{print $3}')
