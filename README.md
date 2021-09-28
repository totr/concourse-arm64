# Concourse CI for linux/arm64

This repository helps you build both the web and worker `arm64` components for Concourse CI - prebuilt Docker images can be found on Docker Hub [rdclda/concourse](https://hub.docker.com/repository/docker/rdclda/concourse).

## Bundled resources

| Concourse | [git](https://github.com/concourse/git-resource) | [github-release](https://github.com/concourse/github-release-resource) | [registry-image](https://github.com/concourse/registry-image-resource) | [semver](https://github.com/concourse/semver-resource) | [time](https://github.com/concourse/time-resource) | [mock](https://github.com/concourse/mock-resource) | [s3](https://github.com/concourse/s3-resource) | [slack-alert](https://github.com/arbourd/concourse-slack-alert-resource) |
|--- |--- |--- |--- |--- |--- |--- |--- |--- |
| v7.1.0 | v1.12.0 | v1.5.2 | v1.2.0 | v1.3.0 | v1.5.0 | v0.11.1 | v1.1.1 | v0.15.0 |
| v7.2.0 | v1.12.1 | v1.5.2 | v1.2.1 | v1.3.0 | v1.6.0 | v0.11.1 | v1.1.1 | v0.15.0 |
| v7.3.2 | v1.14.0 | v1.6.1 | v1.3.0 | v1.3.1 | v1.6.0 | v0.11.2 | v1.1.1 | v0.15.0 |
| v7.4.0 | v1.14.0 | v1.6.4 | v1.4.0 | v1.3.4 | v1.6.1 | v0.12.2 | v1.1.2 | v0.15.0 |
| v7.5.0 | v1.14.4 | v1.6.4 | v1.4.1 | v1.3.4 | v1.6.2 | v0.12.3 | v1.1.3 | v0.15.0 |

## Bundled CLIs

Each Docker image includes the CLIs for Linux/Mac/Windows for the Intel platform - they can be downloaded from the Concourse web console.
## Deploy

Copy the example [docker-compose.yaml](./docker-compose.yaml) to your Raspberry Pi and update the external IP address setting `CONCOURSE_EXTERNAL_URL`.

~~~bash
# On your Raspberry Pi node
$ sudo docker-compose up -d

# Login using fly - update your IP here too ;-)
$ fly --target=my-rpi login \
    --concourse-url=http://10.0.19.18:8080 \
    --username=test \
    --password=test                                                        
~~~

## Tests

These tests are provided to verify the correct working of the bundled resource types. 

~~~bash
# create a public s3 bucket
$ aws s3api create-bucket --acl public-read \
   --bucket rdclda-concourse-s3-test --region us-east-1

# push test file to s3 bucket
$ echo "Looks like the s3 resource is working." | \
   aws s3 cp - s3://rdclda-concourse-s3-test/testfile.txt \
   --acl public-read

# deploy & kick off the tests
$ for resource in registry-image time git s3; do
    fly -t my-rpi set-pipeline -n -p test-${resource}-resource -c tests/$resource-resource.yaml
    fly -t my-rpi unpause-pipeline -p test-${resource}-resource
    fly -t my-rpi trigger-job --job test-${resource}-resource/test-job
done

# deploy Docker Compose in Docker test
$ fly -t my-rpi set-pipeline -n -p test-dcind -c ci-images/dcind/example/pipe.yaml && \
    fly -t my-rpi unpause-pipeline -p test-dcind
    fly -t my-rpi trigger-job --job test-dcind/unit-tests  
~~~

Use the web console to verify the output of the tests.

## BIY

Follow the steps below if you want to build the images yourself.
### Prerequisites

* Raspberry Pi 4 with 8Gb of memory (if you want to build `elm`)
* Docker daemon + Docker CLI (buildx enabled)
* 4Gb of (Docker assigned) memory
* Bash shell

### Build elm

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

### Build Concourse

You will find under the `./build-specs` directory the available configurations for building Concourse CI for `arm64`.

~~~bash
# Kick off the build - specify the concourse version you want to build
./build.sh 7.1.0
~~~

The generated Docker image will be pushed to the specified repository defined in the `.env` file.
