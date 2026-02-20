### DST Docker (2026)

First time setup (downloads the game ~3GB, takes a while):
```
docker build -f Dockerfile.base -t dst-base:latest .
```

Build server images (fast, uses cached game files):
```
docker compose build
```

Start the server:
```
docker compose up
```
or
```
docker compose up -d
```

> No need to rebuild unless you changed `Dockerfile.base` or `start-container-server.sh`.

### Updating the game

To update DST to the latest version, rebuild the base image:
```
docker build -f Dockerfile.base -t dst-base:latest .
docker compose build
docker compose up
```

### Stopping the server