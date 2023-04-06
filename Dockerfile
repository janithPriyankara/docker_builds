FROM fedora:latest
WORKDIR /test
COPY build_script.sh build_script.sh 
CMD ["sh","build_script.sh"]
