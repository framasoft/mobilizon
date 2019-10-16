init:
	@bash docker/message.sh "start"
	make start

start: stop
	@bash docker/message.sh "starting Mobilizon with docker"
	docker-compose up -d api
	docker-compose exec api sh -c "cd js && yarn install && cd ../"
	docker-compose exec api mix deps.get
	docker-compose exec api mix compile
	docker-compose exec api mix ecto.create
	docker-compose exec api mix ecto.migrate
	@bash docker/message.sh "started"
stop:
	@bash docker/message.sh "stopping Mobilizon"
	docker-compose down
	@bash docker/message.sh "stopped"
test: stop
	@bash docker/message.sh "Running tests"
	docker-compose -f docker-compose.yml -f docker-compose.test.yml run api mix test
	@bash docker/message.sh "Tests runned"

target: init
