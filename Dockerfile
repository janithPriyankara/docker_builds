FROM fedora:latest
WORKDIR /test
COPY from_folly from_folly.sh 
CMD ["sh","from_folly.sh"]
