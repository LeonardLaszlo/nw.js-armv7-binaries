# docker image build -t laslaul/nwjs-arm-build-env .
# docker run -it laslaul/nwjs-arm-build-

ARG NWJS_BRANCH

# Use the official image as a parent image
FROM ubuntu:18.04

# Set the working directory
WORKDIR /usr/docker

# Copy the files from your host to your current location
COPY *.sh ./

# Run the command inside your image filesystem
RUN /usr/docker/build-container.sh "$NWJS_BRANCH"
