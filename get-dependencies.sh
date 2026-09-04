#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	binutils            \
	flac                \
	glu                 \
	gvfs                \
	libepoxy            \
	libheif             \
	libsm               \
	librsvg             \
	libtiff             \
	nss                 \
	pipewire-audio      \
	pipewire-jack       \
	pulseaudio-alsa     \
	vulkan-mesa-layers  \
	wget                \
	xcb-util-cursor     \
	xcb-util-keysyms    \
	xcb-util-wm         \
	zsync

if [ "$ARCH" = 'x86_64' ]; then
		pacman -Syu --noconfirm libva-intel-driver
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano intel-media-driver-mini ffmpeg-mini

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

echo "Getting binary..."
echo "---------------------------------------------------------------"
case "$ARCH" in
	aarch64) deb_arch=arm64;;
	x86_64)  deb_arch=amd64;;
esac

CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_${deb_arch}.deb"

mkdir -p ./AppDir/bin /tmp/chrome
wget --retry-connrefused --tries=30 "$CHROME_URL" -O /tmp/chrome/chrome.deb

cd /tmp/chrome
ar xvf ./chrome.deb
tar xvf ./data.tar.xz

mkdir -p /usr/share/applications /usr/share/icons/hicolor/256x256/apps
cp -v ./usr/share/applications/google-chrome.desktop /usr/share/applications/google-chrome.desktop
cp -v ./opt/google/chrome/product_logo_256.png /usr/share/icons/hicolor/256x256/apps/google-chrome.png

tar -xf ./control.tar.* ./control -O | awk -F': |-' '/^Version:/{print $2; exit}' > ~/version

cd -
mv -v /tmp/chrome/opt/google/chrome/* ./AppDir/bin
rm -rf /tmp/chrome

# Symlink so the desktop entry's Exec command (google-chrome-stable) resolves to chrome
ln -sf chrome ./AppDir/bin/google-chrome-stable

# we need to remove this because chrome otherwise dlopen libQt5Core on the host
# when present, we can only bunle libqt6 or libqt5 but not both
rm -f ./AppDir/bin/libqt5_shim.so

chmod 755 .

# if you also have to make nightly releases check for DEVEL_RELEASE = 1
#
# if [ "${DEVEL_RELEASE-}" = 1 ]; then
# 	nightly build steps
# else
# 	regular build steps
# fi
