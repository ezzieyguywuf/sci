# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit cmake-utils multilib

GTEST_PV="1.7.0"

DESCRIPTION="A general purpose GPU library"
HOMEPAGE="http://www.arrayfire.com/"
SRC_URI="http://arrayfire.com/arrayfire_source/${PN}-full-${PV}.tar.bz2 -> ${P}.tar.bz2
test? ( https://googletest.googlecode.com/files/gtest-${GTEST_PV}.zip )"
KEYWORDS="~amd64"

LICENSE="BSD
	nonfree? ( OpenSIFT )"
SLOT="0"
IUSE="+examples +cpu cuda nonfree opencl test unified graphics"

RDEPEND="
	>=sys-devel/gcc-4.7:*
	media-libs/freeimage
	cuda? (
		>=dev-util/nvidia-cuda-toolkit-7.5.18-r1
		dev-libs/boost
	)
	cpu? (
		virtual/blas
		virtual/cblas
		virtual/lapacke
		sci-libs/fftw:3.0
	)
	opencl? (
		virtual/blas
		virtual/cblas
		virtual/lapacke
		dev-libs/boost
		dev-libs/boost-compute
		>=sci-libs/clblas-2.4
		>=sci-libs/clfft-2.6.1
	)
	graphics? (
		media-libs/glew
		>=media-libs/glfw-3.1.1
		=sci-visualization/forge-3.2.0
	)"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${PN}-full-${PV}"
BUILD_DIR="${S}/build"
CMAKE_BUILD_TYPE=Release

# We need write acccess /dev/nvidiactl, /dev/nvidia0 and /dev/nvidia-uvm and the portage
# user is (usually) not in the video group
RESTRICT="userpriv"

pkg_pretend() {
	if [[ ${MERGE_TYPE} != binary ]]; then
		if [[ $(gcc-major-version) -lt 4 ]] || ( [[ $(gcc-major-version) -eq 4 && $(gcc-minor-version) -lt 7 ]] ) ; then
			die "Compilation with gcc older than 4.7 is not supported."
		fi
	fi
}

src_unpack() {
	default

	if ! use nonfree; then
		find "${WORKDIR}" -name "*_nonfree*" -delete || die
	fi

	if use test; then
		mkdir -p "${BUILD_DIR}"/third_party/src/ || die
		mv "${WORKDIR}"/gtest-"${GTEST_PV}" "${BUILD_DIR}"/third_party/src/googletest || die
	fi
}

src_configure() {
	if use cuda; then
		addwrite /dev/nvidiactl
		addwrite /dev/nvidia0
		addwrite /dev/nvidia-uvm
	fi

	local mycmakeargs=(
	   $(cmake-utils_use_build cpu CPU)
	   $(cmake-utils_use_build cuda CUDA)
	   $(cmake-utils_use_build opencl OPENCL)
	   $(cmake-utils_use_build examples EXAMPLES)
	   $(cmake-utils_use_build test TEST)
	   $(cmake-utils_use_build graphics GRAPHICS)
	   $(cmake-utils_use_build nonfree NONFREE)
	   $(cmake-utils_use_build unified UNIFIED)
	   -DUSE_SYSTEM_BOOST_COMPUTE=ON
	   -DUSE_SYSTEM_CLBLAS=ON
	   -DUSE_SYSTEM_CLFFT=ON
	   -DUSE_SYSTEM_FORGE=ON
	   -DAF_INSTALL_CMAKE_DIR=/usr/${get_libdir}/cmake/ArrayFire
	)
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	dobin "${BUILD_DIR}/bin2cpp"
}
