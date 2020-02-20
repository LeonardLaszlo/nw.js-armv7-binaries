# docker image build -t laslaul/nwjs-arm-build-env:1.0 .
# docker run -it laslaul/nwjs-arm-build-env:1.0

# Use the official image as a parent image
FROM ubuntu:16.04

# Set the working directory
WORKDIR /usr/src/nwjs

# Copy the files from your host to your current location
COPY build-container.sh .
COPY build-nwjs.sh .
COPY patch/node-nw.patch .
COPY patch/nwjs.patch .

# Run the command inside your image filesystem
RUN /usr/src/nwjs/build-container.sh
