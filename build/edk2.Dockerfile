FROM debian:11-slim

LABEL maintainer "Eray Ates <eates23@gmail.com>"

RUN	apt-get update && apt-get install -y \
    imagemagick bash make util-linux gcc g++ uuid-dev python3 nasm acpica-tools git openssh-client

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
