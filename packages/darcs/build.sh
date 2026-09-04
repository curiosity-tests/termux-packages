TERMUX_PKG_HOMEPAGE="https://darcs.net/"
TERMUX_PKG_DESCRIPTION="A distributed, interactive, smart revision control system"
TERMUX_PKG_LICENSE="GPL-2.0-or-later"
TERMUX_PKG_MAINTAINER="Aditya Alok <alok@termux.dev>"
TERMUX_PKG_VERSION=2.18.5
TERMUX_PKG_SRCURL="https://hackage.haskell.org/package/darcs-${TERMUX_PKG_VERSION}/darcs-${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256=e310692989e313191824f532a26c5eae712217444214266503d5eb5867f951ab
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_DEPENDS="libffi, libiconv, libgmp, libandroid-posix-semaphore, libandroid-utimes, ncurses, zlib"
TERMUX_PKG_BUILD_DEPENDS="aosp-libs"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--allow-newer=base --allow-newer=Cabal -f+terminfo"

termux_step_pre_configure() {
	mkdir -p autogen
	cat <<-EOF >autogen/Version.hs
		module Version where

		import Darcs.Prelude

		version, weakhash, context :: String
		version = "$TERMUX_PKG_VERSION (release)"
		weakhash = "not available"
		context = "$([[ $(<release/distributed-context) =~ \"(.*)\" ]] && echo -n "${BASH_REMATCH[1]}")"
	EOF
}

termux_step_post_configure() {
	cabal get splitmix-0.1.3.2 && mv splitmix{-*,}
	cabal get basement-0.0.16 && mv basement{-*,}

	for f in "$TERMUX_PKG_BUILDER_DIR"/splitmix-patches/*.patch; do
		patch --silent -p1 -d splitmix <"$f"
	done

	for f in "$TERMUX_PKG_BUILDER_DIR"/basement-patches/*.patch; do
		patch --silent -p1 <"$f"
	done

	echo "packages: splitmix" >>cabal.project.local

	if [[ "$TERMUX_ON_DEVICE_BUILD" == false ]]; then # We do not need iserv for on device builds.
		termux_setup_ghc_iserv
		cat <<-EOF >>cabal.project.local
			package *
				  ghc-options: -fexternal-interpreter -pgmi=$(command -v termux-ghc-iserv)
		EOF
	fi
}
