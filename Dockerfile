FROM dst-base:latest

COPY ["start-container-server.sh", "/home/dst/"]
ENTRYPOINT ["/home/dst/start-container-server.sh"]