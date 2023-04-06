FROM fedora:latest
WORKDIR /test
COPY up-to_folly from_folly.sh 
CMD ["sh","from_folly.sh"]
