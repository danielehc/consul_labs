FROM debian:stretch

COPY ./modern_app_web /

EXPOSE 8080

CMD ["ls","-l", "/"]
