init:
	@bash docker/message.sh "start"
	make start

setup: stop
	@bash docker/message.sh "Compiling everything"
	docker-compose run --rm api bash -c 'mix deps.get; yarn --cwd "js"; yarn --cwd "js" build:pictures; mix ecto.create; mix ecto.migrate'
migrate:
	docker-compose run --rm api mix ecto.migrate
logs:
	docker-compose logs -f
start: stop
	@bash docker/message.sh "starting Mobilizon with docker"
	docker-compose up -d api
	@bash docker/message.sh "Docker server started."
stop:
	@bash docker/message.sh "stopping Mobilizon"
	docker-compose down
	@bash docker/message.sh "stopped"
test: stop
	@bash docker/message.sh "Running tests"
	docker-compose -f docker-compose.yml -f docker-compose.test.yml run api mix test
	@bash docker/message.sh "Tests runned"

target: init
