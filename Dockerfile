FROM fedora:latest
WORKDIR /test
COPY build_script.sh build_sript.sh 
CMD ["sh","build_script.sh"]
