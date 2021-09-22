#!/bin/bash

# set -x
set -e

if [ -f ./build-specs/$1.cfg ]; then
  source ./build-specs/$1.cfg
else
  echo "Provide a Concourse version as first argument."
  echo
  echo "Available configurations:"
  ls -1 ./build-specs | sed 's/\.cfg//g'
  echo
  exit 1
fi

source .env

generateResourceMetdata() {
_type=$1
_version=${2:1}
_privileged=$3

mkdir -p resource-types/$_type

cat << EOF > resource-types/$_type/resource_metadata.json
{
  "type": "$_type",
  "version": "$_version",
  "privileged": $_privileged,
  "unique_version_history": false
}
EOF
}

#
# Build resource type: registry image
docker buildx build \
  --build-arg registry_image_resource_version=$REGISTRY_IMAGE_RESOURCE_VERSION \
  --platform linux/arm64 \
  --tag $DOCKER_REGISTRY_BASE/concourse-registry-image-resource:$REGISTRY_IMAGE_RESOURCE_VERSION \
  --push . \
  -f resource-types/Dockerfile-registry-image-resource

docker create --name registry-image-resource $DOCKER_REGISTRY_BASE/concourse-registry-image-resource:$REGISTRY_IMAGE_RESOURCE_VERSION
mkdir -p resource-types/registry-image
docker export registry-image-resource | gzip \
  > resource-types/registry-image/rootfs.tgz
docker rm -v registry-image-resource
generateResourceMetdata registry-image $REGISTRY_IMAGE_RESOURCE_VERSION false

#
# Build resource type: time
docker buildx build \
  --build-arg time_resource_version=$TIME_RESOURCE_VERSION \
  --platform linux/arm64 \
  --tag $DOCKER_REGISTRY_BASE/concourse-time-resource:$TIME_RESOURCE_VERSION \
  --push . \
  -f resource-types/Dockerfile-time-resource

docker create --name time-resource $DOCKER_REGISTRY_BASE/concourse-time-resource:$TIME_RESOURCE_VERSION
mkdir -p resource-types/time
docker export time-resource | gzip \
  > resource-types/time/rootfs.tgz
docker rm -v time-resource
generateResourceMetdata time $TIME_RESOURCE_VERSION false

#
# Build resource type: semver
docker buildx build \
  --build-arg semver_resource_version=$SEMVER_RESOURCE_VERSION \
  --platform linux/arm64 \
  --tag $DOCKER_REGISTRY_BASE/concourse-semver-resource:$SEMVER_RESOURCE_VERSION \
  --push . \
  -f resource-types/Dockerfile-semver-resource

docker create --name semver-resource $DOCKER_REGISTRY_BASE/concourse-semver-resource:$SEMVER_RESOURCE_VERSION
mkdir -p resource-types/semver
docker export semver-resource | gzip \
  > resource-types/semver/rootfs.tgz
docker rm -v semver-resource
generateResourceMetdata semver $SEMVER_RESOURCE_VERSION false

#
# Build resource type: git
docker buildx build \
  --build-arg git_resource_version=$GIT_RESOURCE_VERSION \
  --platform linux/arm64 \
  --tag $DOCKER_REGISTRY_BASE/concourse-git-resource:$GIT_RESOURCE_VERSION \
  --push . \
  -f resource-types/Dockerfile-git-resource

docker create --name git-resource $DOCKER_REGISTRY_BASE/concourse-git-resource:$GIT_RESOURCE_VERSION
mkdir -p resource-types/git
docker export git-resource | gzip \
  > resource-types/git/rootfs.tgz
docker rm -v git-resource
generateResourceMetdata git $GIT_RESOURCE_VERSION false

#
# Build resource type: concourse-pipeline
docker buildx build \
  --build-arg concourse_pipeline_resource_version=$CONCOURSE_PIPELINE_RESOURCE_VERSION \
  --build-arg concourse_version=$CONCOURSE_VERSION \
  --platform linux/arm64 \
  --tag $DOCKER_REGISTRY_BASE/concourse-pipeline-resource:$CONCOURSE_PIPELINE_RESOURCE_VERSION \
  --push . \
  -f resource-types/Dockerfile-concourse-pipeline-resource

docker create --name concourse-pipeline-resource $DOCKER_REGISTRY_BASE/concourse-pipeline-resource:$CONCOURSE_PIPELINE_RESOURCE_VERSION
mkdir -p resource-types/concourse-pipeline
docker export concourse-pipeline-resource | gzip \
  > resource-types/concourse-pipeline/rootfs.tgz
docker rm -v concourse-pipeline-resource
generateResourceMetdata concourse-pipeline $CONCOURSE_PIPELINE_RESOURCE_VERSION false

#
# Concourse image build
docker buildx build \
  --build-arg concourse_version=$CONCOURSE_VERSION \
  --build-arg cni_plugins_version=$CNI_PLUGINS_VERSION \
  --build-arg guardian_commit_id=$GUARDIAN_COMMIT_ID \
  --build-arg concourse_docker_entrypoint_commit_id=$CONCOURSE_DOCKER_ENTRYPOINT_COMMIT_ID \
  --build-arg elm_version=$ELM_TARBALL_VERSION \
  --build-arg node_version=$NODE_VERSION \
  --platform linux/arm64 \
  --tag $DOCKER_REGISTRY_BASE/concourse:$CONCOURSE_VERSION \
  --push .
