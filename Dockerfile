FROM fedora:latest
WORKDIR /test
COPY up_to_folly from_folly.sh 
CMD ["sh","from_folly.sh"]
