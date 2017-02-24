all: all-packages all-repos

THIS_DIRECTORY := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
COMPONENTS     := $(patsubst src/%.toml,%,$(wildcard src/*.toml))

clear-tmp:
	@git clean -dxf tmp

pull-repo-apt:
	rsync -vau --delete-delay --progress bethselamin:/data/static-web/repo.holocm.org/debian/ repo/debian/
pull-repo: pull-repo-apt

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

clear-packages:
	@rm -f -- pkg/*.deb pkg/*.rpm

packages-%: pkg/%.pkg.toml clear-packages
	cd pkg && holo-build --format=debian ../$< && holo-build --format=rpm ../$<
all-packages: $(patsubst %,packages-%,$(COMPONENTS))

################################################################################
# phase 3.1: generate Apt repo with Aptly

tmp/aptly.conf: clear-tmp
	@mkdir -p tmp
	@echo "{\"rootDir\":\"$(THIS_DIRECTORY)/tmp/aptly\"}" > tmp/aptly.conf

repo-apt: all-packages tmp/aptly.conf clear-tmp
	aptly -config=tmp/aptly.conf repo create -component=main -distribution=stable holo
	aptly -config=tmp/aptly.conf repo add holo pkg/*.deb
	aptly -config=tmp/aptly.conf publish repo -gpg-key="0xD6019A3E17CA2D96" holo
	@mkdir -p repo/debian
	rsync -au --delete-delay tmp/aptly/public/ repo/debian/
all-repos: repo-apt

################################################################################
# phase 4: publish repos to repo.holocm.org

push-repo-apt: repo-apt
	rsync -vau --delete-delay --progress repo/debian/ bethselamin:/data/static-web/repo.holocm.org/debian/
push-repo: push-repo-apt
