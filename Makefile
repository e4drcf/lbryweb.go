VERSION := $(shell git describe --tags)

.PHONY: prepare_test
prepare_test:
	# docker cp conf/test_daemon_settings.yml $(shell docker-compose ps -q test_daemon):/storage/data/daemon_settings.yml
	docker-compose up --no-start test_lbrynet
	docker cp conf/daemon_settings.yml $(shell docker-compose ps -q test_lbrynet):/storage/data/daemon_settings.yml
	docker-compose start test_daemon

.PHONY: test
test:
	go test -cover ./...

.PHONY: test_circleci
test_circleci:
	scripts/wait_for_wallet.sh
	go get golang.org/x/tools/cmd/cover
	go get github.com/mattn/goveralls
	go test -covermode=count -coverprofile=coverage.out ./...
	goveralls -coverprofile=coverage.out -service=circle-ci -repotoken $(COVERALLS_TOKEN)

release:
	goreleaser --rm-dist

snapshot:
	goreleaser --snapshot --rm-dist

.PHONY: image
image:
	docker build -t lbryweb/lbryweb-go:$(VERSION) -t lbryweb/lbryweb-go:latest .

.PHONY: publish_image
publish_image:
	docker push lbryweb/lbryweb-go

embed:
	rice embed-go -i ./routes

clean:
	find . -name rice-box.go | xargs rm
	rm -rf ./dist

.PHONY: server
server:
	LW_DEBUG=1 go run . serve
