# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit versionator toolchain-funcs

DESCRIPTION="A configuration for portage to make building with LTO easy."
HOMEPAGE="https://github.com/InBetweenNames/gentooLTO"
#KEYWORDS="~amd64 ~x86"

SRC_URI=""

LICENSE="GPL-2+"
SLOT="0"
IUSE=""

#portage-bashrc-mv can be obtained from mv overlay
DEPEND=">=sys-devel/gcc-4.9.4:* >=sys-devel/binutils-2.28.1:* app-portage/portage-bashrc-mv[cflags] =sys-devel/gcc-config-9999"
#DEPEND="graphite ? ( gcc[graphite] )"

RDEPEND="${DEPEND}"

#Test binutils and gcc version

pkg_setup() {

	ACTIVE_GCC=$(gcc-fullversion)

	if ! version_is_at_least 7.2.0 "${ACTIVE_GCC}"; then
		ewarn "Warning: Active GCC version < 7.2.0, it is recommended that you use the newest GCC if you want LTO."
		if [ "${I_KNOW_WHAT_I_AM_DOING}" != "y" ]; then
			eerror "Aborting LTOize installation due to older GCC -- set I_KNOW_WHAT_I_AM_DOING=y if you want to override this behaviour."
		else
			ewarn "I_KNOW_WHAT_I_AM_DOING=y -- continuing anyway"
		fi
	fi

	if [ -f "${PORTAGE_CONFIGROOT%/}/etc/portage/package.cflags" ]; then
		eerror "${PORTAGE_CONFIGROOT%/}/etc/portage/package.cflags is a file not a directory.  Please convert package.cflags to a directory with the current contents of package.cflags being moved to a file inside it."
		die
	fi

}

pkg_preinst() {

	GENTOOLTO_PORTDIR=$(portageq get_repo_path / lto-overlay)
	LTO_PORTAGE_DIR="${GENTOOLTO_PORTDIR}/${CATEGORY}/${PN}/files"

	ACTIVE_GCC=$(gcc-fullversion)

	#Insert make.conf sample...

	elog "Installing make.conf.lto sample for make.conf modifications"
	dosym "${LTO_PORTAGE_DIR}/make.conf.lto" "${PORTAGE_CONFIGROOT%/}/etc/portage/make.conf.lto"

	elog "Installing ltoworkarounds.conf package.cflags overrides"
	dosym "${LTO_PORTAGE_DIR}/package.cflags/ltoworkarounds.conf" "${PORTAGE_CONFIGROOT%/}/etc/portage/package.cflags/ltoworkarounds.conf"

	elog "Installing patches to help certain software build with this configuration (installed as symlinks)"
	for i in $(ls ${LTO_PORTAGE_DIR}/patches); do
		dosym "${LTO_PORTAGE_DIR}/patches/$i" "${PORTAGE_CONFIGROOT%/}/etc/portage/patches/$i"
	done

}

pkg_postinst()
{
	elog "If you have not done so, you will need to modify your make.conf settings to enable LTO building on your system."
	elog "A symlink has been placed in ${PORTAGE_CONFIGROOT%/}/etc/portage/make.conf.lto that can be used as a basis for these modifications."
	elog "lto-overlay and ltoize are part of a project to help find undefined behaviour in C and C++ programs through the use of aggressive compiler optimizations."
	elog "One of the aims of this project is also to improve the performance of linux distributions through these mechanisms as well."
	elog "Occasionally, you will experience breakage due to LTO problems.  These are documented in the README.md of this repository."
	elog "If you add an override for a particular package, please consider sending a pull request upstream so that other users of this repository can benefit."
	ewarn "You will require a complete system rebuild in order to gain the benefits of LTO system-wide."
	echo
	elog "Please consider reading the README.md at the root of this repository before attempting to rebuild your system to familiarize yourself with the goals of this project and potential pitfalls you could run into."
	echo
	ewarn "This is an experimental project and should not be used on a stable system in its current state."

	BINUTILS_VER=$(binutils-config -c | sed -e "s/.*-//")

	if ! version_is_at_least 2.29.1 "${BINUTILS_VER}"; then
		ewarn "Warning: active binutils version < 2.29.1, it is recommended that you use the newest binutils for LTO."
	fi

}