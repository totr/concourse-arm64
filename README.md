# Concourse CI for linux/arm64

Builds both web and worker `arm64` components for Concourse CI - a prebuilt Docker image can be found on Docker Hub under [rdclda/concourse](https://hub.docker.com/repository/docker/rdclda/concourse).

## Prerequisites

* Docker daemon + Docker CLI (buildx enabled)
* 2Gb of (Docker assigned) memory
* Bash shell

## Build & publish

You will find under the `./build-specs` directory the available configurations for building Concourse CI for `arm64`.

~~~bash
# Kick off the build - specify the concourse version you want to build
./build.sh v7.1.0
~~~

The generated Docker image will be pushed to the specified repository defined in ther `.env` file and will include the following embedded Concourse resources:

* [concourse-pipeline](https://github.com/concourse/concourse-pipeline-resource)
* [git](https://github.com/concourse/git-resource)
* [registry-image](https://github.com/concourse/registry-image-resource)
* [semver](https://github.com/concourse/semver-resource)
* [time](https://github.com/concourse/time-resource)

## Build elm

Elm is a build dependency for the Concourse web component, but is not available for `arm64` - therefore elm `v0.19.1` has been pre-compiled on `arm64` and packaged under `./dist` within this repository.

The two main reasons to not make the elm native binary compilation part of the Concourse CI build are:

* Docker `buildx` fails (crashes) when trying to compile this on `amd64` platform
* Takes too long

In case you want to build elm yourself, follow the steps below:

~~~bash
# Based upon Ubuntu 20.04
# Raspberry Pi 4 with 8Gb memory and SSD storage attached
# Expect build to take up to 3+ hours
apt-get update && apt-get install ghc cabal-install -y
apt-get install git curl -y

git config --global user.email "info@rdc.pt" && \
git config --global user.name "Robin Daniel Consultants, Lda."

mkdir -p /tmp/build && cd /tmp/build
git clone https://github.com/dmy/elm-raspberry-pi.git ./elm-raspberry-pi
cd ./elm-raspberry-pi && git checkout tags/20200611

cd /tmp/build
git clone https://github.com/elm/compiler.git ./elm/compiler
cd ./elm/compiler && git checkout tags/0.19.1

git am -s /tmp/build/elm-raspberry-pi/patches/elm-0.19.1.patch
cabal new-update
cabal new-configure --ghc-option=-split-sections
cabal new-build
~~~

After the last step, the build will output the elm binary path.
