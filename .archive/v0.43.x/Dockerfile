# docker image build -t laslaul/nwjs-arm-build-env:v0.43.x .
# docker run -it laslaul/nwjs-arm-build-env:v0.43.x

# Use the official image as a parent image
FROM ubuntu:18.04

# Set the working directory
WORKDIR /usr/docker

# Copy the files from your host to your current location
COPY build-container.sh .
COPY build-nwjs.sh .
COPY checkout-another-branch.sh .

# Run the command inside your image filesystem
RUN /usr/docker/build-container.sh
