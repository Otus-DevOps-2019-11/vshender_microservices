USERNAME = vshender

.PHONY: all up down build docker_login \
	build_ui build_comment build_post build_prometheus build_mongodb_exporter build_blackbox_exporter \
	push_ui push_comment push_post push_prometheus push_mongodb_exporter push_blackbox_exporter


all: build


up: build
	cd docker && docker-compose up -d

down:
	cd docker && docker-compose down


build: build_ui build_comment build_post build_prometheus build_mongodb_exporter build_blackbox_exporter

build_ui:
	cd src/ui && bash docker_build.sh

build_comment:
	cd src/comment && bash docker_build.sh

build_post:
	cd src/post-py && bash docker_build.sh

build_prometheus:
	cd monitoring/prometheus && docker build -t ${USERNAME}/prometheus .

build_mongodb_exporter:
	cd monitoring/mongodb && docker build -t ${USERNAME}/mongodb-exporter .

build_blackbox_exporter:
	cd monitoring/blackbox && docker build -t ${USERNAME}/blackbox-exporter .


docker_login:
	docker login


push: push_ui push_comment push_post push_prometheus push_mongodb_exporter push_blackbox_exporter

push_ui: docker_login
	docker push ${USERNAME}/ui

push_comment:
	docker push ${USERNAME}/comment

push_post:
	docker push ${USERNAME}/post

push_prometheus:
	docker push ${USERNAME}/prometheus

push_mongodb_exporter:
	docker push ${USERNAME}/mongodb-exporter

push_blackbox_exporter:
	docker push ${USERNAME}/blackbox-exporter
