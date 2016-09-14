# holo-foreign-repo

This repository is a crude hack for me to provide Debian and RPM packages to
[Holo](https://github.com/holocm/holo) users while I'm only using Arch Linux.
This is in many ways inferior to actual packages built with debuild or
rpmbuild, so help from Debian/Ubuntu/Fedora/Mageia/Suse packagers is very
welcome in getting rid of this.

## How it works

1. The current stable releases of Holo and its components are pinned into this
   repository as submodules below `src/`.
2. The Makefile will first `make check && make install` them into the
   corresponding directories below `pkg/`.
3. After that, `tree-to-pkgspec.sh` will generate a package declaration for
   `holo-build` from these filesystem trees, and `holo-build` will be used to
   produce the actual deb and RPM packages.
4. In a final step, distribution-native tools (`dpkg-scanpackages` and
   `createrepo`) are used to create the repository metadata, and then
   everything is sent to `repo.holocm.org`.

## Note to self: Process for update to new release

```bash
git -C src/$COMPONENT remote update
git -C src/$COMPONENT checkout $TAG
vim src/$COMPONENT.toml # adjust version and release
git add
```
