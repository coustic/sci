# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit eutils flag-o-matic python-any-r1 toolchain-funcs versionator

DESCRIPTION="Scalable Library for Eigenvalue Problem Computations"
HOMEPAGE="http://slepc.upv.es/"
SRC_URI="http://slepc.upv.es/download/distrib/${P}.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="complex-scalars doc mpi"

PETSC_PV="$(get_version_component_range 1-2 ${PV})"
RDEPEND="
	=sci-mathematics/petsc-${PETSC_PV}*:=[mpi=,complex-scalars=]
	sci-libs/arpack[mpi=]
	mpi? ( virtual/mpi )
"

DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	virtual/pkgconfig
	dev-util/cmake
"

MAKEOPTS="${MAKEOPTS} -j1 V=1"

src_prepare() {
	default

	sed -i -e 's%/usr/bin/env python%/usr/bin/env python2%' configure || die
}

src_configure() {
	# *sigh*
	addpredict "${PETSC_DIR}"/.nagged

	# Make sure that the environment is set up correctly:
	unset PETSC_DIR
	unset PETSC_ARCH
	unset SLEPC_DIR
	source "${EPREFIX}"/etc/env.d/99petsc
	export PETSC_DIR

	# configure is a custom python script and doesn't want to have default
	# configure arguments that we set with econf
	./configure \
		--prefix="${EPREFIX}/usr/$(get_libdir)/slepc" \
		--with-arpack=1 \
		--with-arpack-dir="${EPREFIX}/usr/$(get_libdir)" \
		--with-arpack-flags="$(usex mpi "-lparpack,-larpack" "-larpack")"

}

src_install() {
	emake SLEPC_DESTDIR="${D}/usr/$(get_libdir)/slepc" install

	# add PETSC_DIR to environmental variables
	cat >> 99slepc <<- EOF
		SLEPC_DIR=${EPREFIX}/usr/$(get_libdir)/slepc
	EOF
	doenvd 99slepc

	if use doc ; then
		dodoc docs/slepc.pdf
		dohtml -r docs/*.html docs/manualpages
	fi
}
