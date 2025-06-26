ROOTDIR=$(shell pwd)
OUTDIR=${ROOTDIR}/out

TARGETS = rk3399-custom H618-k2b
SOURCE_DIR = ${ROOTDIR}/source
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
	@echo "==> 编译 linux 内核"
	mkdir -p ${OUTDIR}/linux-${LINUX_VERSION}/
	cp ${ROOTDIR}/board/$@/linux-config ${OUTDIR}/linux-${LINUX_VERSION}/.config
	make -C ${SOURCE_DIR}/linux/linux-${LINUX_VERSION} O=${OUTDIR}/linux-${LINUX_VERSION} ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} olddefconfig
	make -C ${SOURCE_DIR}/linux/linux-${LINUX_VERSION} O=${OUTDIR}/linux-${LINUX_VERSION}  ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE}  -j12
	sudo rm -rf ${OUTDIR}/linux-${LINUX_VERSION}/lib/modules/
	sudo make -C ${SOURCE_DIR}/linux/linux-${LINUX_VERSION} O=${OUTDIR}/linux-${LINUX_VERSION}  INSTALL_MOD_STRIP=1 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} -j12 \
		modules_install INSTALL_MOD_PATH=${ROOTDIR}/ubuntu/binary
	@echo "==> 编译 u-boot"
	mkdir -p ${OUTDIR}/u-boot-${UBOOT_VERSION}/
	cp ${ROOTDIR}/board/$@/uboot-config ${OUTDIR}/u-boot-${UBOOT_VERSION}/.config
	make -C ${SOURCE_DIR}/u-boot/u-boot-${UBOOT_VERSION} O=${OUTDIR}/u-boot-${UBOOT_VERSION} \
			ARCH=arm CROSS_COMPILE=${CROSS_COMPILE}  olddefconfig
	make -C ${SOURCE_DIR}/u-boot/u-boot-${UBOOT_VERSION} O=${OUTDIR}/u-boot-${UBOOT_VERSION} \
			-j8 ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} ${MAKE_UBOOT_ARGS}

	@echo "==> 编译 执行hook脚本"
	@bash ${ROOTDIR}/board/$@/hassos-hook.sh ${ROOTDIR}/board/$@ ${OUTDIR} 

	@echo "==> 拷贝产物"
	@bash scripts/copy-images.sh ${ROOTDIR}/board/$@ ${OUTDIR}

	@echo "==> 制作 镜像"
	@bash scripts/mk-image.sh ${ROOTDIR}/board/$@  ${ROOTDIR} ${OUTDIR} 
	@echo "==> 完成 board/$@"

clean:
	@echo "==> 清理编译产物"
	rm -rf ${OUTDIR}/linux-${LINUX_VERSION}
	rm -rf ${OUTDIR}/u-boot-${UBOOT_VERSION}
	sudo rm -rf ${ROOTDIR}/ubuntu/binary/
	rm -rf ${ROOTDIR}/ubuntu/*.img
	rm -rf ${OUTDIR}/*.gz
	rm -rf ${OUTDIR}/*.tar.gz
	rm -rf ${OUTDIR}/*.zip
	rm -rf ${ROOTDIR}/ubuntu/.homeassistantimg
	rm -rf ${ROOTDIR}/ubuntu/.ubuntuimg

cleanall: clean
	@echo "==> 清理所有编译产物"
	rm -rf ${OUTDIR}
	rm -rf ${ROOTDIR}/tool/toolchain
	rm -rf ${ROOTDIR}/ubuntu/binary
	rm -rf ${ROOTDIR}/ubuntu/*.img
	rm -rf ${ROOTDIR}/ubuntu/.homeassistantimg
	rm -rf ${ROOTDIR}/ubuntu/.ubuntuimg

PHONY: clean cleanall $(TARGETS)