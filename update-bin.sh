#!/usr/bin/env bash

# Update bundled `protoc` binary to the latest version.

set -ex

cd "$(dirname "$0")"

crate_version=$(cat protoc-bin-vendored/Cargo.toml | sed -n -e 's/^version = "\([^"]*\)"/\1/p')

tag_name=$(curl -s https://api.github.com/repos/protocolbuffers/protobuf/releases/latest | grep tag_name | cut -d '"' -f 4)
echo "$tag_name" >protoc-bin-vendored/version.txt
echo "updating protoc binaries to version $tag_name" >&2

update_arch() {
    arch="$1"
    crate="$2"

    rm -rf "$crate"
    cp -r protoc-bin-vendored-arch-template "$crate"
    mkdir "$crate/bin"

    exe_suffix=""
    if [ "$arch" = "win32" ]; then
        exe_suffix=".exe"
    fi

    generated="@""generated"

    for file in Cargo.toml src/lib.rs; do
        sed -i~ -e "
            s/@@CRATE_NAME@@/$crate/
            s/@@CRATE_VERSION@@/$crate_version/
            s/@@ARCH@@/$arch/
            s/@@EXE_SUFFIX@@/$exe_suffix/
        " "$crate/$file"
    done

    sed -i~ -e "1 i\\
# $generated by update-bin.sh
    " "$crate/Cargo.toml"

    sed -i~ -e "1 i\\
// $generated by update-bin.sh
    " "$crate/src/lib.rs"

    find "$crate" -name '*~' -delete

    TMPFILE=$(mktemp)
    url="https://github.com/protocolbuffers/protobuf/releases/download/${tag_name}/protoc-${tag_name#v}-${arch}.zip"
    echo "downloading $url..." >&2
    curl -sL "$url" --output "${TMPFILE}.zip"
    unzip "${TMPFILE}.zip" "bin/protoc*" "include/*" -d "$crate"
    chmod +x "$crate/bin/protoc${exe_suffix}"
    rm "${TMPFILE}.zip"
}

update_arch "linux-aarch_64" "protoc-bin-vendored-linux-aarch_64"
update_arch "linux-ppcle_64" "protoc-bin-vendored-linux-ppcle_64"
update_arch "linux-x86_32" "protoc-bin-vendored-linux-x86_32"
update_arch "linux-x86_64" "protoc-bin-vendored-linux-x86_64"
update_arch "osx-aarch_64" "protoc-bin-vendored-macos-aarch_64"
update_arch "osx-x86_64" "protoc-bin-vendored-macos-x86_64"
update_arch "win32" "protoc-bin-vendored-win32"
