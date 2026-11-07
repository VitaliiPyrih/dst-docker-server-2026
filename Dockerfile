FROM dst-base:latest

USER root
COPY ["start-container-server.sh", "/home/dst/"]
RUN chmod +x /home/dst/start-container-server.sh
ENTRYPOINT ["/home/dst/start-container-server.sh"]