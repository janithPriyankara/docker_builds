#!/bin/bash
echo $HOME
BASE_DIR=$PWD
HOME_DIR=$HOME
REPO_DIR="librepos"
INCLUDE_DIR="$HOME_DIR/development/axp/nextgen/3rdparty/include"
LIB_DIR="$HOME_DIR/development/axp/nextgen/3rdparty/lib"
mkdir -p "$HOME_DIR/development/axp/nextgen/3rdparty/include"
mkdir -p "$HOME_DIR/development/axp/nextgen/3rdparty/lib"
mkdir -p $REPO_DIR

uWebSockets_git_tag="v20.9.0"
fmt_git_tag="8.1.1"
folly_git_tag="v2021.08.30.00"Hoodrobin@64
abseil_git_tag="20210324.2"
grpc_git_tag="v1.41.0"
opentelemetry_git_tag="v1.0.0"
prometheus_git_tag="v1.0.0"
spdlog_git_tag="v1.10.0"

cloneLibRepo(){
	git -C librepos clone $1
}

checkoutTag(){
	git --git-dir=$BASE_DIR/$REPO_DIR/$1/.git --work-tree=$BASE_DIR/$REPO_DIR/$1 checkout $2 -b $2
}

executeMakeCommand(){
	make -C $BASE_DIR/$REPO_DIR/$1
}

executeMakeInstall(){
	make install -C $BASE_DIR/$REPO_DIR/$1
}

cloneSubModules(){
	git -C $BASE_DIR/$REPO_DIR/$1 submodule update --init --recursive
} 

cloneCheckoutRepo(){
        cloneLibRepo $1
        checkoutTag $2 $3
        
        #clone submodule
        if [ $4 ]; then
        	cloneSubModules $2
        fi
}

copyFiles(){
        cp $1 $2
} 

copyFilesRecursive(){
        cp -a $1/. $2
} 

installPreLibs(){
	arr=("$@")
	for i in ${arr[@]}; do
  		dnf install $i -y
	done
}

executeCMake(){
	cmake -S $BASE_DIR/$REPO_DIR/$1 -B $BASE_DIR/$REPO_DIR/$1
}

executeCMakeBuild(){
	cmake --build $BASE_DIR/$REPO_DIR/$1
}

buildInstallFollyPreLibs(){
	OLDPATH=$PWD
	cd $BASE_DIR/$REPO_DIR/$1
	./build/fbcode_builder/getdeps.py install-system-deps --recursive
	python3 ./build/fbcode_builder/getdeps.py --allow-system-packages build
	cd $OLDPATH
}

runBashFile(){
	OLDPATH=$PWD
	cd $BASE_DIR/$REPO_DIR/$1
	./$2 $3
	cd $OLDPATH
}

runLdConfig(){
tee /etc/ld.so.conf.d/local.conf <<EOF
/usr/local/lib
/usr/local/lib64
EOF
ldconfig
}

#install pre libraries
preLibs=("python3" "wget" "cmake" "g++" "git-all" "zlib-devel" "auto-make" "openssl" "openssl-devel" "double-conversion-static" "glog-devel" "libunwind-devel" "libtool" "bison" "flex" "byacc" "libcurl" "curl" "libcurl-devel" "gtest-devel" "google-benchmark-devel" "cxxopts-devel" "protobuf-devel" "c-ares-devel" "re2-devel")
installPreLibs "${preLibs[@]}"

##uWebsockets
# cloneCheckoutRepo "https://github.com/uNetworking/uWebSockets.git" "uWebSockets" $uWebSockets_git_tag true
# executeMakeCommand "uWebSockets" 
# executeMakeInstall "uWebSockets"
# copyFiles $BASE_DIR/$REPO_DIR/uWebSockets/uSockets/uSockets.a $LIB_DIR/libuSockets.a 
# copyFilesRecursive $BASE_DIR/$REPO_DIR/uWebSockets/src $INCLUDE_DIR 
# copyFiles $BASE_DIR/$REPO_DIR/uWebSockets/uSockets/src/libusockets.h $INCLUDE_DIR 

# rm -rf $REPO_DIR
# mkdir -p $REPO_DIR


# #install fmt
# cloneCheckoutRepo "https://github.com/fmtlib/fmt.git" "fmt" $fmt_git_tag false
# executeCMake "fmt" 
# executeCMakeBuild "fmt"
# executeMakeCommand "fmt"
# executeMakeInstall "fmt"

# rm -rf $REPO_DIR
# mkdir -p $REPO_DIR

# ## CLean after every installation

# ##folly
# cloneCheckoutRepo "https://github.com/facebook/folly.git" "folly" $folly_git_tag false
# buildInstallFollyPreLibs "folly"
# runBashFile "folly" "build.sh" ""
# executeCMake "folly" 
# executeCMakeBuild "folly"
# executeMakeCommand "folly"
# executeMakeInstall "folly"


rm -rf $REPO_DIR
rm -rf /tmp
mkdir -p $REPO_DIR

###opentelemetry libraries
##abseil-cpp
cloneCheckoutRepo "https://github.com/abseil/abseil-cpp.git" "abseil-cpp" $abseil_git_tag false
cmake -DABSL_USE_GOOGLETEST_HEAD=ON -DCMAKE_CXX_STANDARD=11 -DBUILD_SHARED_LIBS=ON -S $BASE_DIR/$REPO_DIR/abseil-cpp -B $BASE_DIR/$REPO_DIR/abseil-cpp
executeCMakeBuild "abseil-cpp"
executeMakeCommand "abseil-cpp"
executeMakeInstall "abseil-cpp"
runLdConfig

### installed bazel

dnf install c-ares-devel
dnf install re2 re2-devel
git clone --progress -b v3.10.0 https://github.com/protocolbuffers/protobuf && \
    ( \
      cd protobuf; \
      mkdir build; \
      cd build; \
      cmake ../cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -Dprotobuf_BUILD_SHARED_LIBS=ON \
        -Dprotobuf_BUILD_TESTS=OFF; \
      make -j4 install; \
    ) && \
    rm -rf protobuf

rm -rf $REPO_DIR
rm -rf /tmp
mkdir -p $REPO_DIR

##grpc
cloneCheckoutRepo "https://github.com/grpc/grpc.git" "grpc" $grpc_git_tag true
cmake -DgRPC_INSTALL=ON                \
              -DCMAKE_BUILD_TYPE=Release       \
              -DgRPC_ABSL_PROVIDER=package     \
              -DgRPC_CARES_PROVIDER=package    \
              -DgRPC_PROTOBUF_PROVIDER=package \
              -DgRPC_RE2_PROVIDER=package      \
              -DgRPC_SSL_PROVIDER=package      \
              -DBUILD_SHARED_LIBS=ON           \
              -DgRPC_ZLIB_PROVIDER=package -S $BASE_DIR/$REPO_DIR/grpc -B $BASE_DIR/$REPO_DIR/grpc
runLdConfig
executeCMakeBuild "grpc"
executeMakeCommand "grpc"
executeMakeInstall "grpc"
runLdConfig

rm -rf $REPO_DIR
rm -rf /tmp
mkdir -p $REPO_DIR

###opentelemetry-cpp
cloneCheckoutRepo "https://github.com/open-telemetry/opentelemetry-cpp.git" "opentelemetry-cpp" $opentelemetry_git_tag true
runLdConfig
cmake -DWITH_OTLP=ON -DWITH_OTLP_HTTP=ON -DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=ON -S $BASE_DIR/$REPO_DIR/opentelemetry-cpp -B $BASE_DIR/$REPO_DIR/opentelemetry-cpp
executeCMakeBuild "opentelemetry-cpp"
executeMakeCommand "opentelemetry-cpp"
executeMakeInstall "opentelemetry-cpp"

rm -rf $REPO_DIR
rm -rf /tmp
mkdir -p $REPO_DIR

##prometheus-cpp
cloneCheckoutRepo "https://github.com/jupp0r/prometheus-cpp.git" "prometheus-cpp" $prometheus_git_tag true
cmake -DBUILD_SHARED_LIBS=ON -DENABLE_PUSH=OFF -DENABLE_COMPRESSION=OFF -S $BASE_DIR/$REPO_DIR/prometheus-cpp -B $BASE_DIR/$REPO_DIR/prometheus-cpp
runLdConfig
executeCMakeBuild "prometheus-cpp"
executeMakeCommand "prometheus-cpp"
executeMakeInstall "prometheus-cpp"

rm -rf $REPO_DIR
rm -rf /tmp
mkdir -p $REPO_DIR

# ##spdlog
# cloneCheckoutRepo "https://github.com/gabime/spdlog.git" "spdlog" $spdlog_git_tag false
# executeCMake "spdlog"
# executeCMakeBuild "spdlog"
# executeMakeCommand "spdlog"
# executeMakeInstall "spdlog"

# rm -rf $REPO_DIR
# rm -rf /tmp
# mkdir -p $REPO_DIR

# #picojson
# wget https://sftp-release-binaries-migrated.s3.amazonaws.com/sftp/nextgen/third-party-build-libs/pico-json/picojson.h
# mkdir -p $HOME_DIR/development/axp/nextgen/3rdparty/include/picojson
# cp picojson.h $HOME_DIR/development/axp/nextgen/3rdparty/include/picojson


# rm -rf $REPO_DIR
# mkdir -p $REPO_DIR

# #jwt
# wget https://sftp-release-binaries-migrated.s3.amazonaws.com/sftp/nextgen/third-party-build-libs/jwt/base.h
# wget https://sftp-release-binaries-migrated.s3.amazonaws.com/sftp/nextgen/third-party-build-libs/jwt/jwt.h


# mkdir -p $HOME_DIR/development/axp/nextgen/3rdparty/include/JWT
# cp base.h $HOME_DIR/development/axp/nextgen/3rdparty/include/JWT
# cp jwt.h $HOME_DIR/development/axp/nextgen/3rdparty/include/JWT


rm -rf $REPO_DIR
rm -rf /tmp
mkdir -p $REPO_DIR

dnf clean install

echo $BASE_DIR
#sh build_shell_script.sh
