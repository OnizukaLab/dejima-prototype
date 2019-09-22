REPO_PEER ?= yusukew/dejima-peer
REPO_CLIENT ?= yusukew/dejima-client
TAG  ?= $(GITTAG)
GITTAG ?= v0.0.0

all: build push

clean:
	docker rmi $(shell docker images -q $(REPO))

build: Dockerfile
	docker build --build-arg NODE=peer -t $(REPO_PEER):$(TAG) . --no-cache
	docker tag $(REPO_PEER):$(TAG) $(REPO_PEER):latest
	docker build --build-arg NODE=client -t $(REPO_CLIENT):$(TAG) . --no-cache
	docker tag $(REPO_CLIENT):$(TAG) $(REPO_CLIENT):latest
push:
	docker push $(REPO_PEER):$(TAG)
	docker push $(REPO_PEER):latest
	docker push $(REPO_CLIENT):$(TAG)
	docker push $(REPO_CLIENT):latest
