ROOTDIR=$(shell pwd)
OUTDIR=${ROOTDIR}/out

TARGETS = rk3399-custom H618-k2b

.PHONY: rk3399-custom
define FIND_TOOLCHAIN
$(shell find ${ROOTDIR}/tool/toolchain -type f -name 'aarch64-linux-gnu-gcc' | head -n1 | xargs dirname | xargs -I{} echo {}/aarch64-linux-gnu-)
endef

CROSS_COMPILE := $(call FIND_TOOLCHAIN)
ifeq ($(strip $(CROSS_COMPILE)),)
$(info 未找到工具链，正在准备工具链...)
$(shell bash scripts/prepare-toolchain.sh)
CROSS_COMPILE := $(call FIND_TOOLCHAIN)
endif

$(TARGETS):
	@echo "==> 执行 board/$@/config.mk"
	$(eval include board/$@/config.mk)
	@echo "==> 拉取源码"
	@bash scripts/fet-source-code.sh ${ROOTDIR}/board/$@ 
	@echo "==> 打 patch"
	@bash scripts/apply-patch.sh ${ROOTDIR}/board/$@ ${OUTDIR}

	@echo "==> 制作 镜像"
	@bash scripts/mk-image.sh ${ROOTDIR}/board/$@  ${ROOTDIR} ${OUTDIR} 
	@echo "==> 完成 board/$@"