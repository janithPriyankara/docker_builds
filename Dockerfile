FROM fedora:latest
MKDIR /test
COPY from_folly from_folly.sh 
CMD["sh","from_folly.sh"]
