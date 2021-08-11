linux_ver=5.12.19
linux_rel=3
name=linux-ck-uksm
_subarch=14
_gcc_more_v=20210610
_major=5.12
_ckpatchversion=1
_ckpatch=patch-${_major}-ck${_ckpatchversion}
_patches_url="https://gitlab.com/sirlucjan/kernel-patches/-/raw/master/${_major}"

wget -c https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${linux_ver}.tar.xz
wget -c https://github.com/graysky2/kernel_compiler_patch/archive/${_gcc_more_v}.tar.gz
wget -c http://ck.kolivas.org/patches/5.0/${_major}/${_major}-ck${_ckpatchversion}/${_ckpatch}.xz
wget -c ${_patches_url}/uksm-patches/0001-UKSM-for-${_major}.patch
wget -c ${_patches_url}/bbr2-patches-v3/0001-bbr2-patches.patch
wget -c ${_patches_url}/btrfs-patches-v14/0001-btrfs-patches.patch
wget -c ${_patches_url}/block-patches-v7/0001-block-patches.patch
wget -c ${_patches_url}/bfq-patches-v15/0001-bfq-patches.patch
wget -c ${_patches_url}/futex-patches-v2/0001-futex-resync-from-gitlab.collabora.com.patch
wget -c ${_patches_url}/futex2-stable-patches-v7/0001-futex2-resync-from-gitlab.collabora.com.patch
wget -c ${_patches_url}/lru-patches-v4/0001-lru-patches.patch
wget -c ${_patches_url}/zstd-patches-v2/0001-zstd-patches.patch
wget -c ${_patches_url}/initramfs-patches/0001-initramfs-patches.patch
wget -c ${_patches_url}/compaction-patches/0001-compaction-patches.patch
wget -c ${_patches_url}/fixes-miscellaneous/0001-fixes-miscellaneous.patch
wget -c ${_patches_url}/ntfs3-patches-v2/0001-ntfs3-patches.patch

tar -xpvf linux-${linux_ver}.tar.xz
tar -xpvf ${_gcc_more_v}.tar.gz
xz -d ${_ckpatch}.xz

cd linux-${linux_ver}
scripts/setlocalversion --save-scmversion
echo "-$linux_rel" > localversion.10-pkgrel
echo "${name#linux}" > localversion.20-pkgname
for src in $(ls ..); do
  	src="${src%%::*}"
  	src="${src##*/}"
  	[[ $src = 0*.patch ]] || continue
  	echo "Applying patch $src..."
  	patch -Np1 < "../$src"
done 

cp ../config.debian .config

echo "Enable Futex2 support"
scripts/config --enable CONFIG_FUTEX2

echo "Disabling TCP_CONG_CUBIC..."
scripts/config --module CONFIG_TCP_CONG_CUBIC
scripts/config --disable CONFIG_DEFAULT_CUBIC

echo "Enabling TCP_CONG_BBR2..."
scripts/config --enable CONFIG_TCP_CONG_BBR2
scripts/config --enable CONFIG_DEFAULT_BBR2
scripts/config --set-str CONFIG_DEFAULT_TCP_CONG bbr2

echo "Disabling NUMA from kernel config..."
scripts/config --disable CONFIG_NUMA

echo "Set module compression to ZSTD..."
scripts/config --enable CONFIG_MODULE_COMPRESS
scripts/config --disable CONFIG_MODULE_COMPRESS_NONE
scripts/config --disable CONFIG_MODULE_COMPRESS_XZ
scripts/config --enable CONFIG_MODULE_COMPRESS_ZSTD
scripts/config --enable CONFIG_MODULE_COMPRESS_ZSTD_ULTRA

echo "Enable zram compression to ZSTD..."
scripts/config --disable CONFIG_ZRAM_DEF_COMP_LZORLE
scripts/config --enable CONFIG_ZRAM_DEF_COMP_ZSTD
scripts/config --set-str CONFIG_ZRAM_DEF_COMP zstd

scripts/config --disable CONFIG_ZSWAP_COMPRESSOR_DEFAULT_LZ4
scripts/config --enable CONFIG_ZSWAP_COMPRESSOR_DEFAULT_ZSTD
scripts/config --set-str CONFIG_ZSWAP_COMPRESSOR_DEFAULT zstd

echo "Enabling multigenerational LRU..."
scripts/config --enable CONFIG_HAVE_ARCH_PARENT_PMD_YOUNG
scripts/config --enable CONFIG_LRU_GEN
scripts/config --set-val CONFIG_NR_LRU_GENS 7
scripts/config --set-val CONFIG_TIERS_PER_GEN 4
scripts/config --enable CONFIG_LRU_GEN_ENABLED
scripts/config --disable CONFIG_LRU_GEN_STATS

scripts/config --disable CONFIG_DEBUG_INFO
scripts/config --disable CONFIG_CGROUP_BPF
scripts/config --disable CONFIG_BPF_LSM
scripts/config --disable CONFIG_BPF_PRELOAD
scripts/config --disable CONFIG_BPF_LIRC_MODE2
scripts/config --disable CONFIG_BPF_KPROBE_OVERRIDE

scripts/config --enable CONFIG_PSI_DEFAULT_DISABLED

scripts/config --disable CONFIG_LATENCYTOP
scripts/config --disable CONFIG_SCHED_DEBUG

scripts/config --disable CONFIG_KVM_WERROR

sed -i -re "s/^(.EXTRAVERSION).*$/\1 = /" "../${_ckpatch}"

patch -Np1 -i ../"${_ckpatch}"

make olddefconfig

patch -Np1 -i "../kernel_compiler_patch-${_gcc_more_v}/more-uarches-for-kernel-5.8+.patch"

if [[ -n "${_subarch}" ]]; then
	yes "${_subarch}" | make oldconfig
fi
make -s kernelrelease > version

make deb-pkg KDEB_PKGVERSION=$(make kernelversion)-${linux_rel} -j40
