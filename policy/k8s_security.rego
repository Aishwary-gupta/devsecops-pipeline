package main

# List of approved container registries
allowed_registries := [
    "ghcr.io/devsecops-org/",
    "docker.io/myorg/",
    "123456789012.dkr.ecr.us-east-1.amazonaws.com/"
]

# Rule 1: Containers must run as non-root
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot == true
    not input.spec.template.spec.securityContext.runAsNonRoot == true
    msg := sprintf("[OPA-001] Container '%v' in Deployment '%v' must have 'runAsNonRoot: true'", [container.name, input.metadata.name])
}

# Rule 2: Memory and CPU limits must be defined
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("[OPA-002] Container '%v' in Deployment '%v' must define memory limits to prevent DoS", [container.name, input.metadata.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("[OPA-003] Container '%v' in Deployment '%v' must define CPU limits to prevent noisy-neighbor starvation", [container.name, input.metadata.name])
}

# Rule 3: Disallow 'latest' image tag in production
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("[OPA-004] Container '%v' must use an immutable tagged image version, not ':latest' ('%v')", [container.name, container.image])
}

# Rule 4: Containers must drop ALL Linux capabilities
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    dropped := [c | c := container.securityContext.capabilities.drop[_]; c == "ALL"]
    count(dropped) == 0
    msg := sprintf("[OPA-005] Container '%v' must drop ALL capabilities in securityContext.capabilities.drop", [container.name])
}

# Rule 5: Root filesystem must be read-only
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.readOnlyRootFilesystem == true
    msg := sprintf("[OPA-006] Container '%v' must set readOnlyRootFilesystem: true", [container.name])
}

# Rule 6: Image must originate from an approved organizational container registry
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    image := container.image
    valid_prefix := [prefix | prefix := allowed_registries[_]; startswith(image, prefix)]
    count(valid_prefix) == 0
    msg := sprintf("[OPA-007] Container '%v' image '%v' comes from an unapproved registry. Allowed prefixes: %v", [container.name, image, allowed_registries])
}

# Rule 7: High Availability replica minimum
deny[msg] {
    input.kind == "Deployment"
    input.metadata.namespace == "production"
    input.spec.replicas < 2
    msg := sprintf("[OPA-008] Production Deployment '%v' must specify at least 2 replicas for high availability (found: %v)", [input.metadata.name, input.spec.replicas])
}
