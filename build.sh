#!/bin/bash

set -x
set -e

# Private Docker registry settings
DOCKER_REGISTRY_BASE=rdclda

# Concourse resource types build settings
REGISTRY_IMAGE_RESOURCE_VERSION=v1.4.1
TIME_RESOURCE_VERSION=v1.6.2
SEMVER_RESOURCE_VERSION=v1.3.4
GIT_RESOURCE_VERSION=v1.14.4
CONCOURSE_PIPELINE_RESOURCE_VERSION=v6.0.1

# Concourse web build settings
ELM_TARBALL_VERSION=v0.19.1
NODE_VERSION=v14.17.6

# Concourse worker build settings
CONCOURSE_VERSION=v7.1.0
CNI_PLUGINS_VERSION=v0.8.7
GUARDIAN_COMMIT_ID=51480bc73a282c02f827dde4851cc12265774272

# Concourse image build settings
CONCOURSE_DOCKER_ENTRYPOINT_COMMIT_ID=486894e6d6f84aad112c14094bca18bec8c48154

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
  -f Dockerfile-registry-image-resource

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
  -f Dockerfile-time-resource

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
  -f Dockerfile-semver-resource

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
  -f Dockerfile-git-resource

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
  -f Dockerfile-concourse-pipeline-resource

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
