# Docker

You can quickly get a server running using Docker. You'll need both [Docker](https://www.docker.com/community-edition) and [Docker-Compose](https://docs.docker.com/compose/install/).

Start by cloning the repo
```bash
git clone https://framagit.org/framasoft/mobilizon && cd mobilizon
```

Then, just run `make` to build containers.
```bash
make
```

This will start a database container, an API container and the front-end container running on localhost.
