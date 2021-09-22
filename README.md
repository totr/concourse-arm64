# Concourse CI for linux/arm64

```
./build.sh
```

Will build the docker registry-image resource, zip it and put it in the
right path. Will then build the main docker file which builds concourse
first and then uses the binaries in a fresh docker image.

While this does not cross-compile, it can be run on arm machines with docker.

## Build elm

Version xxx is packaged within this repository, 

~~~bash
# FROM debian:buster-slim AS elm-arm64

# RUN apt-get update && apt-get install ghc cabal-install -y
# RUN apt-get install git curl -y

# RUN git config --global user.email "info@rdc.pt" && \
#       git config --global user.name "Robin Daniel Consultants, Lda."

# WORKDIR /build/elm-raspberry-pi
# ARG elm_raspberry_pi_version=20200611
# RUN git clone https://github.com/dmy/elm-raspberry-pi.git /build/elm-raspberry-pi
# RUN git checkout tags/${elm_raspberry_pi_version}

# WORKDIR /build/elm/compiler
# ARG elm_compiler_version=0.19.1
# RUN git clone https://github.com/elm/compiler.git /build/elm/compiler
# RUN git checkout tags/${elm_compiler_version}
# RUN git am -s /build/elm-raspberry-pi/patches/elm-${elm_compiler_version}.patch
# RUN cabal new-update
# RUN cabal new-configure --ghc-option=-split-sections
# RUN cabal new-build
~~~