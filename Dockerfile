# docker image build -t laslaul/nwjs-arm-build-env:1.1 .
# docker run -it laslaul/nwjs-arm-build-env:1.1

# Use the official image as a parent image
FROM ubuntu:18.04

# Set the working directory
WORKDIR /usr/docker

# Copy the files from your host to your current location
COPY build-container.sh .
COPY build-nwjs.sh .

# Run the command inside your image filesystem
RUN /usr/docker/build-container.sh
