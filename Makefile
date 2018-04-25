.PHONY: init
init:
	@yarn

.PHONY: test
test:
	@yarn run test
	@fish ./test-bins.fish
