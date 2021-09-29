FROM golang:1.16.2-alpine3.13 as builder

ARG oci_build_task_version

RUN apk add git
RUN git clone --depth 1 --branch v${oci_build_task_version} https://github.com/concourse/oci-build-task.git /src/oci-build-task
WORKDIR /src/oci-build-task
ENV CGO_ENABLED 0
RUN go get -d ./...
RUN go build -o /assets/task ./cmd/task
RUN go build -o /assets/build ./cmd/build

FROM moby/buildkit:v0.8.3 AS task
COPY --from=builder /assets/task /usr/bin/
COPY --from=builder /assets/build /usr/bin/
COPY --from=builder /src/oci-build-task/bin/setup-cgroups /usr/bin/
ENTRYPOINT ["task"]

FROM task
