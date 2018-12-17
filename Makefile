init:
	@bash docker/message.sh "start"
	make start

start: stop
	@bash docker/message.sh "starting MobiliZon with docker"
	docker-compose up -d
	@bash docker/message.sh "started"
stop:
	@bash docker/message.sh "stopping MobiliZon"
	docker-compose down
	@bash docker/message.sh "stopped"

target: init
