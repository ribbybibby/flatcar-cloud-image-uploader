DOCKER_REPO=quay.io/kinvolk

.PHONY: build
build:
	for i in $$(ls -d */ | cut -d/ -f1); do docker build --pull -t $(DOCKER_REPO)/$$i:$$(git describe --always) $$i; done

.PHONY: tag-latest
tag-latest:
	for i in $$(ls -d */ | cut -d/ -f1); do docker tag $(DOCKER_REPO)/$$i:$$(git describe --always) $(DOCKER_REPO)/$$i:latest; done

.PHONY: push
push:
	for i in $$(ls -d */ | cut -d/ -f1); do docker push $(DOCKER_REPO)/$$i:$$(git describe --always); done

.PHONY: push-latest
push-latest:
	for i in $$(ls -d */ | cut -d/ -f1); do docker push $(DOCKER_REPO)/$$i:latest; done

.PHONY: all
all: build tag-latest push push-latest
