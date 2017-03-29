# ---------------------------------------------------------

VERSION := 0.1.0

BINARY := deploy-kube.tar
SOURCE := Dockerfile docker-entrypoint.sh

DOCKER_IMAGE := continuul/deploy-kube

.DEFAULT_GOAL: $(IMAGE)

# ---------------------------------------------------------
# Rules
# ---------------------------------------------------------

$(BINARY): $(SOURCE)
	@rm -f deploy-kube.tar
	@docker build --no-cache -t $(DOCKER_IMAGE):$(VERSION) .
	@docker save $(DOCKER_IMAGE) > deploy-kube.tar

# ---------------------------------------------------------
# Targets
# ---------------------------------------------------------

.PHONY: all
all: clean image

.PHONY: prune
prune:
	@docker rm $(docker ps -q -f status=exited) > /dev/null 2>&1 | true
	@docker system prune -f

.PHONY: clean
clean:
	@docker rmi -f $(DOCKER_IMAGE) > /dev/null 2>&1 | true
	@docker rmi -f $(DOCKER_IMAGE):$(VERSION) > /dev/null 2>&1 | true
	@rm -f $(BINARY)

image: $(BINARY)

.PHONY: push
push:
	@docker login
	@docker push $(DOCKER_IMAGE):$(VERSION)

