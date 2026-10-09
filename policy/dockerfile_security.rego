package main

# Deny Dockerfiles running as root
deny[msg] {
    input[i].Cmd == "user"
    val := input[i].Value
    contains(val, "root")
    msg := sprintf("[OPA-DOCKER-001] Dockerfile specifies root user at step %v", [i])
}

# Deny base images using :latest
deny[msg] {
    input[i].Cmd == "from"
    val := input[i].Value
    endswith(val, ":latest")
    msg := sprintf("[OPA-DOCKER-002] Dockerfile uses ':latest' base image: %v", [val])
}
