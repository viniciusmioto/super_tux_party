#!/bin/sh -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: release <target> <version>"
    exit 1
fi

if [ "$1" != "release" ] &&  [ "$1" != "nightly" ]; then
	echo "target must be either 'release' or 'nightly'"
	exit 1
fi

finalize_build () {
	cd build
	
	zip -r ../super-tux-party-linux-64.zip plugins supertuxparty supertuxparty.pck
	zip -r ../super-tux-party-windows-64.zip plugins Supertuxparty.exe Supertuxparty.pck
	zip -r ../super-tux-party-linux-server-64.zip plugins supertuxparty_server supertuxparty_server.pck
	
	cp -r plugins 'supertuxparty.app/Contents/Resources/plugins'
	zip -r ../super-tux-party-osx-64.zip 'supertuxparty.app'
	cd ..
}

itch_deploy() {
	butler push super-tux-party-linux-64.zip "$1:linux-64" --userversion="$2"
	butler push super-tux-party-windows-64.zip "$1:windows-64" --userversion="$2"
	butler push super-tux-party-osx-64.zip "$1:osx-64" --userversion="$2"
	butler push super-tux-party-osx-64.zip "$1:server-64" --userversion="$2"
	butler push super-tux-party-sources.zip "$1:sources" --userversion="$2"
}

website_deploy() {
	sftp upload@supertux.party:files <<EOF
mkdir "$1"
cd "$1"
put super-tux-party-linux-64.zip linux.zip
put super-tux-party-windows-64.zip windows.zip
put super-tux-party-osx-64.zip macos.zip
put super-tux-party-linux-server-64.zip server.zip
put super-tux-party-sources.zip source.zip
EOF
}

finalize_build

if [ "$1" = "release" ]; then
	itch_deploy anti/super-tux-party "$2"
	website_deploy "$2"

	# Update the symlink for latest
	sftp upload@supertux.party << EOF
rm files/latest
symlink "$2" files/latest
EOF
else
	itch_deploy supertuxparty/super-tux-party-nightly "$2"
	website_deploy nightly
fi
