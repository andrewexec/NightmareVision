#!/bin/bash
set -e

DEBS=~/arm64-sysroot-debs
SYSROOT=~/arm64-sysroot
WAYLAND_DEBS=~/wayland-tools-debs
WAYLAND_TOOLS=~/wayland-tools
WIN_SYSROOT=/mnt/c/arm64-sysroot

mkdir -p "$DEBS" "$SYSROOT" "$WAYLAND_DEBS" "$WAYLAND_TOOLS"

cd "$DEBS"
PKGS="
  libasound2-dev libasound2t64
  libpulse-dev libpulse0
  libx11-dev libx11-6
  libxext-dev libxext6
  libxrandr-dev libxrandr2
  libxcursor-dev libxcursor1
  libxi-dev libxi6
  libxss-dev libxss1
  libxxf86vm-dev libxxf86vm1
  libxinerama-dev libxinerama1
  libxfixes-dev libxfixes3
  libxrender-dev libxrender1
  libxkbcommon-dev libxkbcommon0
  libgl-dev libgl1
  libegl-dev libegl1
  libgles2
  libwayland-dev libwayland-client0 libwayland-cursor0 libwayland-egl1
  libdbus-1-dev libdbus-1-3
  libudev-dev libudev1
  libdecor-0-dev libdecor-0-0
  libpipewire-0.3-dev libpipewire-0.3-0t64
  libspa-0.2-dev
  libjack-jackd2-dev libjack-jackd2-0
  libsndio-dev libsndio7.0
  libsystemd-dev libsystemd0
  libxau-dev libxau6
  libxdmcp-dev libxdmcp6
  libxcb1-dev libxcb1
  libglx-dev libglvnd-dev mesa-common-dev
  libdrm-dev libdrm2
  libgbm-dev libgbm1
  libvlc-dev libvlc5
  libvlccore-dev libvlccore9
"
for p in $PKGS; do
  echo "=== $p ==="
  apt-get download "${p}:arm64" 2>&1 || echo "  (skip: not found for arm64)"
done
apt-get download x11proto-dev 2>&1

echo "=== extracting to $SYSROOT ==="
for deb in "$DEBS"/*.deb; do
  dpkg-deb -x "$deb" "$SYSROOT"
done


cd "$WAYLAND_DEBS"
apt-get download libwayland-bin wayland-protocols 2>&1
for deb in *.deb; do
  dpkg-deb -x "$deb" "$WAYLAND_TOOLS"
done

echo "=== copying sysroot to $WIN_SYSROOT (dereferencing symlinks) ==="
rm -rf "$WIN_SYSROOT"
mkdir -p "$WIN_SYSROOT"
cp -rL "$SYSROOT"/* "$WIN_SYSROOT"/ 2>&1 | grep -v -e "Too many levels" -e "cannot stat" -e "cannot create regular file" || true

echo "=== generating SDL wayland protocol files ==="
SDL_LIB="/mnt/c/Users/Andrew/Documents/GitHub/NightmareVision/.haxelib/lime/git/project/lib/sdl"
PROTOCOLS="$SDL_LIB/wayland-protocols"
OUT="$SDL_LIB/wayland-generated-protocols"
mkdir -p "$OUT"
for xml in "$PROTOCOLS"/*.xml; do
  base=$(basename "$xml" .xml)
  out="$OUT/${base}-client-protocol"
  "$WAYLAND_TOOLS/usr/bin/wayland-scanner" client-header "$xml" "${out}.h"
  "$WAYLAND_TOOLS/usr/bin/wayland-scanner" private-code "$xml" "${out}.c"
done

echo "Done. C:/arm64-sysroot is ready, and wayland-generated-protocols has $(ls "$OUT" | wc -l) files."
echo "Reminder: merge projFiles/hxcpp_config_arm64_snippet.xml into your ~/.hxcpp_config.xml (or"
echo "%USERPROFILE%\\.hxcpp_config.xml on Windows) if you haven't already - it's outside this repo"
echo "and not something this script can safely auto-merge."
