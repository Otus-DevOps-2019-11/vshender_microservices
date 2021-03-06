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
- A `docker-compose.yml` file was added to run the application.

  ```
  $ export USERNAME=vshender
  $ cd src

  $ docker-compose up -d
  $ docker-compose ps
      Name                  Command             State           Ports
  ----------------------------------------------------------------------------
  src_comment_1   puma                          Up
  src_db_1        docker-entrypoint.sh mongod   Up      27017/tcp
  src_post_1      python3 post_app.py           Up
  src_ui_1        puma                          Up      0.0.0.0:9292->9292/tcp

  ```
- The `docker-compose.yml` was changed to run the application containers on two bridge networks.
- The `docker-compose.yml` was parameterized.
- The project name was changed.

  ```
  $ docker-compose -p reddit up -d
  Creating network "reddit_back_net" with the default driver
  Creating network "reddit_front_net" with the default driver
  Creating volume "reddit_post_db" with default driver
  Creating reddit_db_1      ... done
  Creating reddit_ui_1      ... done
  Creating reddit_post_1    ... done
  Creating reddit_comment_1 ... done

  ```
- The `docker-compose.override.yml` file was added.


# Homework 18: gitlab-ci-1

- Gitlab deployment was implemented.

  ```
  $ cd gitlab-ci/gitlab/terraform
  $ cp terraform.tfvars.example terraform.tfvars
  $ terraform apply -auto-approve

  $ cd ../ansible
  $ ansible-playbook site.yml
  ```
- Pipeline definition was added.
- A Gitlab runner was started and registered.

  ```
  $ ssh -i ~/.ssh/appuser gitlab@34.76.120.42
  $ sudo docker run -d --name gitlab-runner --restart always \
  >   -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  >   -v /var/run/docker.sock:/var/run/docker.sock \
  >   gitlab/gitlab-runner:latest
  $ sudo docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false
  ```
- The reddit application code was added to the repository.
- An unit test for the reddit application is added.
- `dev` stage and environment are defined.
- `stage` and `production` stages are defined.
- `stage` and `production` stages are limited to run only for tags.
- A dynamic environment for branches was added.
- The reddit application container building is implemented.

  Registering GitLab runner to use `docker` and `privileged` mode in order to be able to build docker images:
  ```
  $ ssh -i ~/.ssh/appuser gitlab@34.76.120.42
  $ sudo docker run -d --name gitlab-runner --restart always \
  >   -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  >   -v /var/run/docker.sock:/var/run/docker.sock \
  >   gitlab/gitlab-runner:latest
  $ sudo docker exec -it gitlab-runner gitlab-runner register \
  >   --url http://34.76.120.42/ \
  >   --registration-token A1QzuKmatFF3QYoxT-M4 \
  >   --executor docker \
  >   --docker-image "docker:19.03.1" \
  >   --docker-privileged \
  >   --run-untagged \
  >   --locked=false
  ```
- A server creation and the application deployment for review environment is implemented.

  The following GitLab CI variables are required to be defined:
  - `DOCKER_HUB_LOGIN` -- docker hub login;
  - `DOCKER_HUB_PASSWD` -- docker hub password;
  - `GCP_PROJECT_NAME` -- a name of GCP project where GitLab is deployed;
  - `GCP_SERVICE_ACCOUNT_KEY` -- base64-encoded GCP service account key.
- GitLab runners creation is implemented.

  ```
  $ cd gitlab-ci/gitlab/ansible
  $ ansible-playbook site.yml --extra-vars "runner_token=uLEPyD8FR_9mjEhx_cG3 runners_count=2" --tags=create_runners
  ```
- GitLab integration with Slack is implemented.

  You can check GitLab notifications here: https://devops-team-otus.slack.com/archives/GSFU43CHG.


# Homework 19: monitoring-1

- Got acquainted with Prometheus.

  Starting Prometheus in docker machine:
  ```
  $ gcloud compute firewall-rules create prometheus-default --allow tcp:9090
  $ gcloud compute firewall-rules create puma-default --allow tcp:9292

  $ export GOOGLE_PROJECT=docker-272823
  $ docker-machine create --driver google \
  >   --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1804-lts \
  >   --google-machine-type n1-standard-1 \
  >   --google-zone europe-west1-b \
  >   docker-host
  $ eval $(docker-machine env docker-host)

  $ docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus

  $ docker-machine ip docker-host
  ```
- A Prometheus Docker image is built to monitor the application.

  ```
  $ cd monitoring/prometheus
  $ export USERNAME=vshender
  $ docker build -t $USERNAME/prometheus .
  ```
- The application microservices images are built.
  ```
  $ for srv in ui post-py comment; do cd src/$srv; bash docker_build.sh; cd -; done
  ```
- Prometheus service was added to `docker/docker-compose.yml` file.
- Node-exporter was added to monitoring.

  ```
  $ cd monitoring/prometheus
  $ docker build -t $USERNAME/prometheus .

  $ cd ../../docker
  $ docker-compose down
  $ docker-compose up -d
  ```
- The created images are pushed to DockerHub.

  ```
  $ docker login
  $ for image in ui comment post prometheus; do docker push $USERNAME/$image; done
  ```

  DockerHub profile: https://hub.docker.com/u/vshender.
- MongoDB monitoring was implemented using [mongodb_exporter](https://github.com/percona/mongodb_exporter).
- Blackbox monitoring was implemented using [blackbox_exporter](https://github.com/prometheus/blackbox_exporter).
- A `Makefile` was added to automate several actions.
