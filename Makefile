include config.mk

# get main- and subtarget name from TARGET
MAINTARGET=$(word 1, $(subst _, ,$(TARGET)))
SUBTARGET=$(word 2, $(subst _, ,$(TARGET)))

GIT_REPO=git config --get remote.origin.url
GIT_BRANCH=git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,'
REVISION=git describe --always

FW_REVISION=$(shell $(REVISION))

# set dir and file names
FW_DIR=$(shell pwd)
LEDE_SRC_DIR=$(FW_DIR)/source
TARGET_CONFIG=$(FW_DIR)/configs/common.config $(FW_DIR)/configs/$(TARGET).config
IB_BUILD_DIR=$(FW_DIR)/imgbldr_tmp
FW_TARGET_DIR=$(FW_DIR)/lede/$(FW_REVISION)/targets/$(MAINTARGET)/$(SUBTARGET)
PACKAGE_TARGET_DIR=$(FW_DIR)/lede/$(FW_REVISION)
UMASK=umask 022

# if any of the following files have been changed: clean up lede dir
DEPS=$(TARGET_CONFIG) feeds.conf patches $(wildcard patches/*)

# profiles to be built (router models)
PROFILES=$(shell cat $(FW_DIR)/profiles/$(TARGET).profiles || echo noprofile)

default: firmwares

# clone lede
$(LEDE_SRC_DIR):
	git clone $(LEDE_SRC) $(LEDE_SRC_DIR)

# clean up lede working copy
lede-clean: stamp-clean-lede-cleaned .stamp-lede-cleaned
.stamp-lede-cleaned: config.mk | $(LEDE_SRC_DIR) lede-clean-bin
	cd $(LEDE_SRC_DIR); \
	  ./scripts/feeds clean && \
	  git clean -dff && git fetch && git reset --hard HEAD && \
	  rm -rf .config feeds.conf build_dir/target-* logs/
	touch $@

lede-clean-bin:
	rm -rf $(LEDE_SRC_DIR)/bin

# update lede and checkout specified commit
lede-update: stamp-clean-lede-updated .stamp-lede-updated
.stamp-lede-updated: .stamp-lede-cleaned
	cd $(LEDE_SRC_DIR); git checkout --detach $(LEDE_COMMIT)
	touch $@

# patches require updated lede working copy
$(LEDE_SRC_DIR)/patches: | .stamp-lede-updated
	ln -s $(FW_DIR)/patches $@

# feeds
$(LEDE_SRC_DIR)/feeds.conf: .stamp-lede-updated feeds.conf
	cp $(FW_DIR)/feeds.conf $@

# update feeds
feeds-update: stamp-clean-feeds-updated .stamp-feeds-updated
.stamp-feeds-updated: $(LEDE_SRC_DIR)/feeds.conf unpatch
	+cd $(LEDE_SRC_DIR); \
	  ./scripts/feeds uninstall -a && \
	  ./scripts/feeds update && \
	  ./scripts/feeds install -a
	touch $@

# prepare patch
pre-patch: stamp-clean-pre-patch .stamp-pre-patch
.stamp-pre-patch: .stamp-feeds-updated $(wildcard $(FW_DIR)/patches/*) | $(LEDE_SRC_DIR)/patches
	touch $@

# patch lede working copy
patch: stamp-clean-patched .stamp-patched
.stamp-patched: .stamp-pre-patch
	cd $(LEDE_SRC_DIR); quilt push -a
	touch $@

.stamp-build_rev: .FORCE
ifneq (,$(wildcard .stamp-build_rev))
ifneq ($(shell cat .stamp-build_rev),$(FW_REVISION))
	echo $(FW_REVISION) | diff >/dev/null -q $@ - || echo -n $(FW_REVISION) >$@
endif
else
	echo -n $(FW_REVISION) >$@
endif

# lede config
$(LEDE_SRC_DIR)/.config: .stamp-patched $(TARGET_CONFIG) .stamp-build_rev
	cat $(TARGET_CONFIG) >$(LEDE_SRC_DIR)/.config
	sed -i "/^CONFIG_VERSION_NUMBER=/ s/\"$$/\-$(FW_REVISION)\"/" $(LEDE_SRC_DIR)/.config
	sed -i "/^CONFIG_VERSION_REPO=/ s/\"$$/\/$(FW_REVISION)\"/" $(LEDE_SRC_DIR)/.config
	$(UMASK); \
	  $(MAKE) -C $(LEDE_SRC_DIR) defconfig

# prepare lede working copy
prepare: stamp-clean-prepared .stamp-prepared
.stamp-prepared: .stamp-patched $(LEDE_SRC_DIR)/.config
	sed -i 's,^# REVISION:=.*,REVISION:=$(FW_REVISION),g' $(LEDE_SRC_DIR)/include/version.mk
	touch $@

# compile
compile: stamp-clean-compiled .stamp-compiled
.stamp-compiled: .stamp-prepared lede-clean-bin
	$(UMASK); \
	  $(MAKE) -C $(LEDE_SRC_DIR) $(MAKE_ARGS)
	touch $@

# fill firmwares-directory with:
#  * firmwares built with imagebuilder
#  * imagebuilder file
#  * packages directory
firmwares: stamp-clean-firmwares .stamp-firmwares
.stamp-firmwares: .stamp-compiled
	rm -rf $(IB_BUILD_DIR)
	mkdir -p $(IB_BUILD_DIR)
	$(eval TOOLCHAIN_PATH := $(shell printf "%s:" $(LEDE_SRC_DIR)/staging_dir/toolchain-*/bin))
	$(eval IB_FILE := $(shell ls $(LEDE_SRC_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*imagebuilder*.tar.bz2))
	cd $(IB_BUILD_DIR); tar xf $(IB_FILE)
	# shorten dir name to prevent too long paths
	mv $(IB_BUILD_DIR)/$(shell basename $(IB_FILE) .tar.bz2) $(IB_BUILD_DIR)/imgbldr
	export PATH=$(PATH):$(TOOLCHAIN_PATH); \
	PACKAGES_PATH="$(FW_DIR)/packages"; \
	PACKAGES_FILE_TARGET="$(FW_DIR)/packages/$(TARGET).txt"; \
	for PROFILE_ITER in $(PROFILES); do \
	  for PACKAGES_FILE in $(PACKAGES_LIST_DEFAULT); do \
	    PROFILE=$$PROFILE_ITER \
	    CUSTOM_POSTINST_PARAM=""; \
	    if [[ $$PROFILE =~ ":" ]]; then \
	      SUFFIX="$$(echo $$PROFILE | cut -d':' -f 2)"; \
	      PACKAGES_SUFFIXED="$${PACKAGES_FILE}_$${SUFFIX}"; \
	      if [[ -f "$$PACKAGES_PATH/$$PACKAGES_SUFFIXED.txt" ]]; then \
	        PACKAGES_FILE="$$PACKAGES_SUFFIXED"; \
	        PROFILE=$$(echo $$PROFILE | cut -d':' -f 1); \
	      fi; \
	    fi; \
	    if [[ -f "$$PACKAGES_PATH/$$PACKAGES_FILE.sh" ]]; then \
	      CUSTOM_POSTINST_PARAM="CUSTOM_POSTINST_SCRIPT=$$PACKAGES_PATH/$$PACKAGES_FILE.sh"; \
	    fi; \
	    PACKAGES_FILE_ABS="$$PACKAGES_PATH/$$PACKAGES_FILE.txt"; \
	    PACKAGES_LIST=$$(grep -v '^\#' $$PACKAGES_FILE_ABS | tr -t '\n' ' '); \
	    if [[ -f "$$PACKAGES_FILE_TARGET" ]]; then \
	       PACKAGES_LIST="$$PACKAGES_LIST $$(grep -v '^\#' $$PACKAGES_FILE_TARGET | tr -t '\n' ' ')"; \
	    fi; \
	    $(UMASK);\
	    echo -e "\n *** Building Kathleen image file for profile \"$${PROFILE}\" with packages list \"$${PACKAGES_FILE}\".\n"; \
	    $(MAKE) -C $(IB_BUILD_DIR)/imgbldr image PROFILE="$$PROFILE" PACKAGES="$$PACKAGES_LIST" BIN_DIR="$(IB_BUILD_DIR)/imgbldr/bin/$$PACKAGES_FILE" $$CUSTOM_POSTINST_PARAM || exit 1; \
	    cp -a $(IB_BUILD_DIR)/imgbldr/build_dir/target-*/root-*/usr/lib/opkg/status $(IB_BUILD_DIR)/imgbldr/bin/$$PACKAGES_FILE/opkg-status.txt ;\
	  done; \
	done
	mkdir -p $(FW_TARGET_DIR)
	# Create version info file
	GIT_BRANCH_ESC=$(shell $(GIT_BRANCH) | tr '/' '_'); \
	VERSION_FILE=$(FW_TARGET_DIR)/VERSION.txt; \
	echo "https://github.com/freifunk-berlin/firmware" > $$VERSION_FILE; \
	echo "https://wiki.freifunk.net/Berlin:Firmware" >> $$VERSION_FILE; \
	echo "Firmware: git branch \"$$GIT_BRANCH_ESC\", revision $(FW_REVISION)" >> $$VERSION_FILE; \
	# add lede revision with data from config.mk \
	LEDE_REVISION=`cd $(LEDE_SRC_DIR); $(REVISION)`; \
	echo "LEDE project: repository from $(LEDE_SRC), git branch \"$(LEDE_COMMIT)\", revision $$LEDE_REVISION" >> $$VERSION_FILE; \
	# add feed revisions \
	for FEED in `cd $(LEDE_SRC_DIR); ./scripts/feeds list -n`; do \
	  FEED_DIR=$(addprefix $(LEDE_SRC_DIR)/feeds/,$$FEED); \
	  FEED_GIT_REPO=`cd $$FEED_DIR; $(GIT_REPO)`; \
	  FEED_GIT_BRANCH_ESC=`cd $$FEED_DIR; $(GIT_BRANCH) | tr '/' '_'`; \
	  FEED_REVISION=`cd $$FEED_DIR; $(REVISION)`; \
	  echo "Feed $$FEED: repository from $$FEED_GIT_REPO, git branch \"$$FEED_GIT_BRANCH_ESC\", revision $$FEED_REVISION" >> $$VERSION_FILE; \
	done
	# copy different firmwares (like vpn, minimal) including imagebuilder
	for DIR_ABS in $(IB_BUILD_DIR)/imgbldr/bin/*; do \
	  TARGET_DIR=$(FW_TARGET_DIR)/$$(basename $$DIR_ABS); \
	  rm -rf $$TARGET_DIR; \
	  mv $$DIR_ABS $$TARGET_DIR; \
	  cp $(FW_TARGET_DIR)/$$VERSION_FILE $$TARGET_DIR/; \
	  for FILE in $$TARGET_DIR/lede*; do \
	    [ -e "$$FILE" ] || continue; \
	    NEWNAME="$${FILE/lede-/paul-}"; \
	    NEWNAME="$${NEWNAME/ar71xx-generic-/}"; \
	    NEWNAME="$${NEWNAME/mpc85xx-generic-/}"; \
	    NEWNAME="$${NEWNAME/squashfs-/}"; \
	    mv "$$FILE" "$$NEWNAME"; \
	  done; \
	done;
	# copy imagebuilder, sdk and toolchain (if existing)
	# remove old versions
	rm -f $(FW_TARGET_DIR)/*imagebuilder*.tar.bz2
	cp -a $(IB_FILE) $(FW_TARGET_DIR)/
	# copy core packages
	mkdir -p $(FW_TARGET_DIR)/packages
	cp -a $(LEDE_SRC_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/packages $(FW_TARGET_DIR)
	# copy base, luci and routing packages
	mkdir -p $(PACKAGE_TARGET_DIR)
	cp -a $(LEDE_SRC_DIR)/bin/packages $(PACKAGE_TARGET_DIR)
	rm -rf $(IB_BUILD_DIR)
	touch $@

stamp-clean-%:
	rm -f .stamp-$*

stamp-clean:
	rm -f .stamp-*

# unpatch needs "patches/" in lede
unpatch: $(LEDE_SRC_DIR)/patches
# RC = 2 of quilt --> nothing to be done
	cd $(LEDE_SRC_DIR); quilt pop -a -f || [ $$? = 2 ] && true
	rm -f .stamp-patched

clean: stamp-clean .stamp-lede-cleaned

.PHONY: lede-clean lede-clean-bin lede-update patch feeds-update prepare compile firmwares stamp-clean clean
.NOTPARALLEL:
.FORCE:
