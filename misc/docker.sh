function docker_build() {
    # Build docker file first if not exist image
    output=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "${DOCKER_IMAGE}")
    if [[ ! $output ]]; then
        echo "Please download or build ${DOCKER_IMAGE} image first!"
        return 1
    fi
}

function docker_run() {
    docker run --rm -it \
        -v $(pwd):/workspace/project \
        --user $(id -u):$(id -g) \
        ${DOCKER_IMAGE}
        bash -c "${ALL_ARGS}"
}

function docker_pass() {
    docker_build && docker_run
}
