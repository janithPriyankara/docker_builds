FROM fedora:latest
WORKDIR /test
COPY from_folly.sh from_folly.sh 
CMD ["sh","from_folly.sh"]
