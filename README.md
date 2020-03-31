# vshender_microservices
vshender microservices repository

## Homework #15: docker-2

- Outputs of `docker inspect` for container and image are compared.
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
