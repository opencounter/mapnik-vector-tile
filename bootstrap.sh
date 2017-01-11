#!/usr/bin/env bash

MASON_VERSION="707311610a662920a2bd3a3b70be36b071fe9bb7"

function setup_mason() {
    if [[ ! -d ./.mason ]]; then
        git clone https://github.com/mapbox/mason.git ./.mason
        (cd ./.mason && git checkout ${MASON_VERSION})
    else
        echo "Updating to latest mason"
        (cd ./.mason && git fetch && git checkout ${MASON_VERSION})
    fi
    export PATH=$(pwd)/.mason:$PATH
    export CXX=${CXX:-clang++}
    export CC=${CC:-clang}
}

function install() {
    MASON_PLATFORM_ID=$(mason env MASON_PLATFORM_ID)
    if [[ ! -d ./mason_packages/${MASON_PLATFORM_ID}/${1}/ ]]; then
        mason install $1 $2
        # the rm here is to workaround https://github.com/mapbox/mason/issues/230
        rm -f ./mason_packages/.link/mason.ini
        mason link $1 $2
    fi
}

ICU_VERSION="55.1"

function install_mason_deps() {
    FAIL=0
    install mapnik latest &
    install geometry 0.9.0 &
    install ccache 3.2.4 &
    install jpeg_turbo 1.5.0 libjpeg &
    install libpng 1.6.24 libpng &
    install libtiff 4.0.6 libtiff &
    install libpq 9.5.2 &
    install sqlite 3.14.1 libsqlite3 &
    install expat 2.2.0 libexpat &
    install icu ${ICU_VERSION} &
    install proj 4.9.2 libproj &
    install pixman 0.34.0 libpixman-1 &
    install cairo 1.14.6 libcairo &
    install protobuf 2.6.1 &
    # technically protobuf is not a mapnik core dep, but installing
    # here by default helps make mapnik-vector-tile builds easier
    install webp 0.5.1 libwebp &
    install gdal 2.1.1 libgdal &
    install boost 1.62.0 &
    install boost_libsystem 1.62.0 &
    install boost_libfilesystem 1.62.0 &
    install boost_libprogram_options 1.62.0 &
    install boost_libregex_icu 1.62.0 &
    # technically boost thread and python are not a core dep, but installing
    # here by default helps make python-mapnik builds easier
    install boost_libthread 1.62.0 &
    install boost_libpython 1.62.0 &
    install freetype 2.6.5 libfreetype &
    install harfbuzz 1.3.0 libharfbuzz &
    for job in $(jobs -p)
    do
        wait $job || let "FAIL+=1"
    done
    if [[ "$FAIL" != "0" ]]; then
        exit ${FAIL}
    fi
}

function setup_runtime_settings() {
    local MASON_LINKED_ABS=$(pwd)/mason_packages/.link
    export PROJ_LIB=${MASON_LINKED_ABS}/share/proj
    export ICU_DATA=${MASON_LINKED_ABS}/share/icu/${ICU_VERSION}
    export GDAL_DATA=${MASON_LINKED_ABS}/share/gdal
    if [[ $(uname -s) == 'Darwin' ]]; then
        export DYLD_LIBRARY_PATH=$(pwd)/mason_packages/.link/lib:${DYLD_LIBRARY_PATH}
        # OS X > 10.11 blocks DYLD_LIBRARY_PATH so we pass along using a
        # differently named variable
        export MVT_LIBRARY_PATH=${DYLD_LIBRARY_PATH}
    else
        export LD_LIBRARY_PATH=$(pwd)/mason_packages/.link/lib:${LD_LIBRARY_PATH}
    fi
    export PATH=$(pwd)/mason_packages/.link/bin:${PATH}
}

function main() {
    setup_mason
    install_mason_deps
    setup_runtime_settings
    echo "Ready, now run:"
    echo ""
    echo "    make test"
}

main
