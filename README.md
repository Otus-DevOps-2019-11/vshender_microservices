# vshender_microservices
vshender microservices repository

## Homework #15: docker-2

- The outputs of `docker inspect` for container and image are compared.
- A docker machine is created in GCP.

  ```
  $ export GOOGLE_PROJECT=docker-272823
  $ docker-machine create \
      --driver google \
      --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
      --google-machine-type n1-standard-1 \
      --google-zone europe-west1-b \
      docker-host
  $ docker-machine ls
  $ eval $(docker-machine env docker-host)
  ```
- The output of the following two commands is compared.

  ```
  $ docker run --rm -it tehbilly/htop
  $ docker run --rm --pid host -it tehbilly/htop
  ```

  `htop` from the last command displays all host processes.
- The reddit application docker image is built.

  ```
  $ cd docker-monolith
  $ docker build -t reddit:latest .
  $ docker images -a
  $ docker run --name reddit -d --network=host reddit:latest
  ```
- Firewall for the reddit application is configured.

  ```
  $ gcloud compute firewall-rules create reddit-app \
      --allow tcp:9292 \
      --target-tags=docker-machine \
      --description="Allow PUMA connections" \
      --direction=INGRESS
  ```
- The reddit application docker image is pushed to Docker Hub.

  ```
  $ docker login
  $ docker tag reddit:latest vshender/otus-reddit:1.0
  $ docker push vshender/otus-reddit:1.0
  $ eval $(docker-machine env --unset)
  $ docker run --name reddit -d -p 9292:9292 vshender/otus-reddit:1.0
  ```
- The reddit application deployment is implemented.

  ```
  $ cd docker-monolith/infra

  $ cd packer
  $ packer build -var-file=variables.json.example docker-host.json

  $ cd ../terraform
  $ cp terraform.tfvars.example terraform.tfvars
  $ terraform apply -auto-approve

  $ cd ../ansible
  $ ansible-playbook site.yml
  ```


## Homework #16: docker-3

- The reddit application microservices code is added to the repository.
- Dockerfiles for building the application images are added.

  ```
  $ eval $(docker-machine env docker-host)
  $ cd src

  $ docker build -t vshender/post:1.0 ./post-py
  $ docker build -t vshender/comment:1.0 ./comment
  $ docker build -t vshender/ui:1.0 ./ui

  $ docker images
  ...
  vshender/ui            1.0                 8a2611b70db3        13 hours ago        785MB
  vshender/comment       1.0                 3e81cc25be92        13 hours ago        783MB
  vshender/post          1.0                 eddd02228a5d        13 hours ago        110MB
  ...

  $ docker network create reddit
  $ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
  $ docker run -d --network=reddit --network-alias=post vshender/post:1.0
  $ docker run -d --network=reddit --network-alias=comment vshender/comment:1.0
  $ docker run -d --network=reddit -p 9292:9292 vshender/ui:1.0
  ```
- The application containers were ran using different network aliases.

  ```
  $ docker kill $(docker ps -q)
  $ docker run -d \
      --network=reddit \
      --network-alias=post_database \
      --network-alias=comment_database \
      mongo:latest
  $ docker run -d \
      --network=reddit \
      --network-alias=post_service \
      -e POST_DATABASE_HOST=post_database \
      vshender/post:1.0
  $ docker run -d \
      --network=reddit \
      --network-alias=comment_service \
      -e COMMENT_DATABASE_HOST=comment_database \
      vshender/comment:1.0
  $ docker run -d \
      --network=reddit \
      -p 9292:9292 \
      -e POST_SERVICE_HOST=post_service \
      -e COMMENT_SERVICE_HOST=comment_service \
      vshender/ui:1.0
  ```
- The sizes of `comment` and `ui` images were optimized using an ubuntu base image.

  ```
  $ docker build -t vshender/comment:2.0 ./comment
  $ docker build -t vshender/ui:2.0 ./ui
  $ docker images
  ...
  vshender/comment       2.0                 ba6920b63efb        59 minutes ago      410MB
  vshender/ui            2.0                 92a971bcd851        About an hour ago   413MB
  ...
  ```
- The sizes of the images were optimized using alpine base images.

  ```
  $ docker build -t vshender/post:2.0 ./post-py
  $ docker build -t vshender/comment:3.0 ./comment
  $ docker build -t vshender/ui:2.0 ./ui
  $ docker images
  ...
  vshender/ui            5.0                 f2868053f86b        11 minutes ago      70.9MB
  vshender/comment       5.0                 16a976961632        14 minutes ago      68.8MB
  vshender/post          2.0                 e192d362ab91        20 minutes ago      106MB
  ```
- A docker volume was used to store MongoDB data.

  ```
  $ docker volume create reddit_db
  $ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
  ```


## Homework 17: docker-4

- `none` and `host` network drivers are compared.

  - None driver:

    ```
    $ docker run --rm --network none joffotron/docker-net-tools -c ifconfig
    lo        Link encap:Local Loopback
              ...
    ```
  - Host driver:

    ```
    $ docker run --rm --network host joffotron/docker-net-tools -c ifconfig
    br-bf66b55fd9b7 Link encap:Ethernet  HWaddr 02:42:1B:02:08:96
              ...
    docker0   Link encap:Ethernet  HWaddr 02:42:C0:10:15:7D
              ...
    ...

    $ docker-machine ssh docker-host ifconfig
    br-bf66b55fd9b7 Link encap:Ethernet  HWaddr 02:42:1B:02:08:96
              ...
    docker0   Link encap:Ethernet  HWaddr 02:42:C0:10:15:7D
              ...
    ...
    ```
- The application containers were run on two bridge networks so that `ui` service didn't have access to the DB.

  ```
  $ docker network create back_net --subnet=10.0.2.0/24
  $ docker network create front_net --subnet=10.0.1.0/24

  $ docker run -d --network=front_net -p 9292:9292 --name ui vshender/ui:1.0
  $ docker run -d --network=back_net --name comment vshender/comment:1.0
  $ docker run -d --network=back_net --name post vshender/post:1.0
  $ docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db mongo:latest

  $ docker network connect front_net post
  $ docker network connect front_net comment

  docker-user@docker-host:~$ docker-machine ssh docker-host
  docker-user@docker-host:~$ sudo apt update && sudo apt install bridge-utils

  docker-user@docker-host:~$ sudo docker network ls
  NETWORK ID          NAME                DRIVER              SCOPE
  1af853b61403        back_net            bridge              local
  6fd07b1132ce        bridge              bridge              local
  8f055d1c48aa        front_net           bridge              local
  f305ef17bd01        host                host                local
  0388399f09e7        none                null                local

  docker-user@docker-host:~$ ifconfig | grep br
  br-1af853b61403 Link encap:Ethernet  HWaddr 02:42:4f:18:e0:0a
  br-8f055d1c48aa Link encap:Ethernet  HWaddr 02:42:83:62:f3:85

  docker-user@docker-host:~$ brctl show br-1af853b61403
  bridge name             bridge id               STP enabled     interfaces
  br-1af853b61403         8000.02424f18e00a       no              veth20b5c99
                                                                  veth545d995
                                                                  veth920337d
  docker-user@docker-host:~$ brctl show br-8f055d1c48aa
  bridge name             bridge id               STP enabled     interfaces
  br-8f055d1c48aa         8000.02428362f385       no              veth2d8c526
                                                                  veth39230ec
                                                                  veth58234b0

  docker-user@docker-host:~$ sudo iptables -nL -t nat
  Chain PREROUTING (policy ACCEPT)
  target     prot opt source               destination
  DOCKER     all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

  Chain INPUT (policy ACCEPT)
  target     prot opt source               destination

  Chain OUTPUT (policy ACCEPT)
  target     prot opt source               destination
  DOCKER     all  --  0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

  Chain POSTROUTING (policy ACCEPT)
  target     prot opt source               destination
  MASQUERADE  all  --  10.0.1.0/24          0.0.0.0/0
  MASQUERADE  all  --  10.0.2.0/24          0.0.0.0/0
  MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0
  MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0
  MASQUERADE  tcp  --  10.0.1.2             10.0.1.2             tcp dpt:9292

  Chain DOCKER (2 references)
  target     prot opt source               destination
  RETURN     all  --  0.0.0.0/0            0.0.0.0/0
  RETURN     all  --  0.0.0.0/0            0.0.0.0/0
  RETURN     all  --  0.0.0.0/0            0.0.0.0/0
  RETURN     all  --  0.0.0.0/0            0.0.0.0/0
  DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9292 to:10.0.1.2:9292

  docker-user@docker-host:~$ ps -ef | grep docker-proxy
  root     25503  5563  0 17:45 ?        00:00:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292
  ```
