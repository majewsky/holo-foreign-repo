all: all-packages

THIS_DIRECTORY := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
COMPONENTS     := $(patsubst src/%.toml,%,$(wildcard src/*.toml))

################################################################################
# phase 1: build components and install to pkg/$COMPONENT/

build-%: src/$*
	make -C src/$* check
all-build: $(patsubst %,build-%,$(COMPONENTS))

install-%: build-% pkg/$*
	make -C src/$* install DESTDIR=$(THIS_DIRECTORY)/pkg/$*
all-install: $(patsubst %,install-%,$(COMPONENTS))

################################################################################
# phase 2: generate packages through holo-build

pkg/%.pkg.toml: install-% tree-to-pkgspec.sh
	$(THIS_DIRECTORY)/tree-to-pkgspec.sh $*
all-pkg-toml: $(patsubst %,pkg/%.pkg.toml,$(COMPONENTS))

clear-repo-directory:
	@rm -f -- repo/*.deb repo/*.rpm

packages-%: pkg/%.pkg.toml clear-repo-directory
	cd repo && holo-build --debian ../$< && holo-build --rpm ../$<
all-packages: $(patsubst %,packages-%,$(COMPONENTS))
