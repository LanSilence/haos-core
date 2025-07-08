# 基础变量定义
V ?= 0
ifeq ($(V),1)
    Q =
else
    Q = @
endif

ROOTDIR := $(shell pwd)
OUTDIR := ${ROOTDIR}/out
SOURCE_DIR := ${ROOTDIR}/source
TARGETS := rk3399-custom H618-k2b
.PHONY: $(TARGETS) clean cleanall

# 工具链查找 - 只执行一次
TOOLCHAIN_PATH := $(shell find ${ROOTDIR}/tool/toolchain -type f -name 'aarch64-linux-gnu-gcc' | head -n1 | xargs dirname)
CROSS_COMPILE := $(if $(TOOLCHAIN_PATH),$(TOOLCHAIN_PATH)/aarch64-linux-gnu-)

ifeq ($(strip $(CROSS_COMPILE)),)
$(info 未找到工具链，正在准备工具链...)
$(shell bash scripts/prepare-toolchain.sh)
TOOLCHAIN_PATH := $(shell find ${ROOTDIR}/tool/toolchain -type f -name 'aarch64-linux-gnu-gcc' | head -n1 | xargs dirname)
CROSS_COMPILE := $(TOOLCHAIN_PATH)/aarch64-linux-gnu-
endif

# 并行编译设置
PARALLEL_JOBS := $(shell nproc)
LINUX_JOBS := $(shell echo $$(($(PARALLEL_JOBS)+2)))
UBOOT_JOBS := $(shell echo $$(($(PARALLEL_JOBS)-2)))

# 目标规则
$(TARGETS):
	$(Q)echo "==> 执行 board/$@/config.mk"
	$(eval include board/$@/config.mk)
	
	# 检查是否需要清理
	@if [ -f ${OUTDIR}/.last_target ] && [ "$$(cat ${OUTDIR}/.last_target)" != "$@" ]; then \
		echo "==> 清理旧编译产物 (切换目标从 $$(cat ${OUTDIR}/.last_target) 到 $@)"; \
		rm -rf $(CLEAN_FILES); \
	fi
	@echo "$@" > ${OUTDIR}/.last_target
	
	$(Q)echo "==> 拉取源码"
	$(Q)set -e; bash scripts/fet-source-code.sh ${ROOTDIR}/board/$@ 
	$(Q)echo "==> 打 patch"
	$(Q)set -e; bash scripts/apply-patch.sh ${ROOTDIR}/board/$@ ${OUTDIR} 
	$(Q)echo "==> 编译 linux 内核"
	@mkdir -p ${OUTDIR}/linux-${LINUX_VERSION}/
	@cp ${ROOTDIR}/board/$@/linux-config ${OUTDIR}/linux-${LINUX_VERSION}/.config
	$(Q)set -e; make -C ${SOURCE_DIR}/linux/linux-${LINUX_VERSION} O=${OUTDIR}/linux-${LINUX_VERSION} \
		ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} olddefconfig
	$(Q)set -e; make -C ${SOURCE_DIR}/linux/linux-${LINUX_VERSION} O=${OUTDIR}/linux-${LINUX_VERSION} \
		ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} -j$(LINUX_JOBS)
	$(Q)rm -rf ${ROOTDIR}/ubuntu/binary/usr/lib/modules/
	$(Q)set -e; make -C ${SOURCE_DIR}/linux/linux-${LINUX_VERSION} O=${OUTDIR}/linux-${LINUX_VERSION} \
		INSTALL_MOD_STRIP=1 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} -j$(LINUX_JOBS) \
		modules_install INSTALL_MOD_PATH=${ROOTDIR}/ubuntu/binary/usr
	$(Q)echo "==> 编译 u-boot"
	@mkdir -p ${OUTDIR}/u-boot-${UBOOT_VERSION}/
	$(Q)cp ${ROOTDIR}/board/$@/uboot-config ${OUTDIR}/u-boot-${UBOOT_VERSION}/.config
	$(Q)set -e; make -C ${SOURCE_DIR}/u-boot/u-boot-${UBOOT_VERSION} O=${OUTDIR}/u-boot-${UBOOT_VERSION} \
		ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} olddefconfig
	$(Q)set -e; make -C ${SOURCE_DIR}/u-boot/u-boot-${UBOOT_VERSION} O=${OUTDIR}/u-boot-${UBOOT_VERSION} \
		-j$(UBOOT_JOBS) ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} ${MAKE_UBOOT_ARGS}

	$(Q)echo "==> 执行hook脚本"
	$(Q)set -e; bash ${ROOTDIR}/board/$@/hassos-hook.sh ${ROOTDIR}/board/$@ ${OUTDIR} 

	$(Q)echo "==> 拷贝产物"
	$(Q)set -e; bash scripts/copy-images.sh ${ROOTDIR}/board/$@ ${OUTDIR}

	$(Q)echo "==> 制作镜像"
	$(Q)set -e; bash scripts/mk-image.sh ${ROOTDIR}/board/$@ ${ROOTDIR} ${OUTDIR} 
	$(Q)echo "==> 完成 board/$@"

# 清理规则
CLEAN_FILES := \
	${OUTDIR}/linux-${LINUX_VERSION} \
	${OUTDIR}/u-boot-${UBOOT_VERSION} \
	${ROOTDIR}/ubuntu/binary/ \
	${OUTDIR}/*.gz \
	${OUTDIR}/*.tar.gz \
	${OUTDIR}/*.zip \
	${ROOTDIR}/ubuntu/.ubuntuimg \
	${ROOTDIR}/ubuntu/hass-core \
	${OUTDIR}/.last_target

CLEANALL_FILES := \
	${CLEAN_FILES} \
	${OUTDIR} \
	${ROOTDIR}/cache \
	${ROOTDIR}/tool/toolchain \
	${ROOTDIR}/ubuntu/cache \
	${ROOTDIR}/ubuntu/rootfs.tar.gz \
	${ROOTDIR}/ubuntu/*.img \
	${ROOTDIR}/ubuntu/.homeassistantimg \

clean:
	$(Q)echo "==> 清理编译产物"
	$(Q)rm -rf $(CLEAN_FILES)

cleanall: clean
	$(Q)echo "==> 清理所有编译产物"
	$(Q)rm -rf $(CLEANALL_FILES)

PHONY: clean cleanall $(TARGETS)
