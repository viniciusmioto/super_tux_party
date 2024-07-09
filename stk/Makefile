
.PHONY: all clean linux windows linux_executable windows_executable macos macos_executable resources

all: linux windows macos

build:
	mkdir build

build/plugins:
	mkdir build/plugins

linux: linux_executable resources

linux_executable: build
	godot --export-release --headless "Linux Client" "build/supertuxparty" --no-window

resources: build build/plugins
	godot --export-release --headless "Resources" "build/plugins/default.pck" --no-window


windows: windows_executable resources

windows_executable: build
	godot --export-release --headless "Windows Desktop" "build/Supertuxparty.exe" --no-window

macos: macos_executable resources

macos_executable:
	godot --export-release --headless "Mac OSX Client" "build/supertuxparty.app" --no-window

install:
	mkdir -p /usr/share/supertuxparty
	echo '#!/bin/sh\ncd $(dirname $(realpath $0))\n./supertuxparty'> /usr/share/supertuxparty/run.sh
	chmod +x /usr/share/supertuxparty/run.sh
	cp build/supertuxparty /usr/share/supertuxparty
	cp build/supertuxparty.pck /usr/share/supertuxparty
	cp -r build/plugins /usr/share/supertuxparty/plugins
	ln -sf /usr/share/supertuxparty/run.sh /bin/supertuxparty

clean:
	rm -rf build
