#!/bin/sh

ARCH=$(uname -m)
SRC_DIR=$GF_PATHS_HOME

GO_ARCH_AMD64="https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz"
GO_ARCH_PPC64LE="https://dl.google.com/go/go${GO_VERSION}.linux-ppc64le.tar.gz"

NODEJS_ARCH_AMD64="https://nodejs.org/dist/v10.16.0/node-v${NODEJS_VERSION}-linux-x64.tar.xz"
NODEJS_ARCH_PPC64LE="https://nodejs.org/dist/v10.16.0/node-v${NODEJS_VERSION}-linux-ppc64le.tar.xz"

print_error()
{
	echo "error: $1"
}

run_wget()
{
	url="$1"
	file=${url##*/}
	dir=${file%.tar.*}

	if [ ! -e $file ]; then
		wget $url
		if [ $? -ne 0 ]; then
			print_error "wget $file" && exit 1
		fi
	fi

	case $file in
		*.gz)  tar xvzf $file ;;
		*.xz)  tar xvf  $file ;;
		*.bz2) tar xvjf $file ;;
	esac

}


install_go()
{
	run_wget $GO_URL
	PATH=$(pwd)/go/bin:$PATH
	rm -rf $file
}

install_nodejs()
{
	run_wget $NODEJS_URL
	PATH=$(pwd)/$dir/bin:$PATH
	PATH=$(npm bin):$PATH
	rm -rf $file
}

remove_go()
{
	rm -rf $SRC_DIR/go
}

remove_node()
{
	rm -rf $SRC_DIR/node*
}

remove_src_grafana()
{
	rm -rf $SRC_DIR/src
}

install_grafana()
{
	export GOPATH=$SRC_DIR
	go get -v github.com/grafana/grafana

	cd $GOPATH/src/github.com/grafana/grafana
	go run build.go setup
	go run build.go build

	npm install -g yarn
	yarn install --pure-lockfile
	yarn run build

	export PATH=$(pwd)/bin:$PATH

	groupadd -r -g $GF_GID grafana
	useradd -r -u $GF_UID -g grafana grafana

	mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
		 "$GF_PATHS_PROVISIONING/dashboards" \
		 "$GF_PATHS_LOGS" \
		 "$GF_PATHS_PLUGINS" \
		 "$GF_PATHS_DATA"

	mv -f bin/**/*  $GF_PATHS_HOME/bin
	mv    public    $GF_PATHS_HOME/public
	mv    conf      $GF_PATHS_HOME/conf

	chown -R grafana:grafana $GF_PATHS_HOME
	chmod 777 $GF_PATHS_DATA \
	   $GF_PATHS_LOGS \
	   $GF_PATHS_PLUGINS
}

mkdir -p $SRC_DIR
cd $SRC_DIR


if [ "$ARCH" = "x86_64" ]; then
	GO_URL=$GO_ARCH_AMD64
	NODEJS_URL=$NODEJS_ARCH_AMD64
elif [ "$ARCH" = "ppc64le" ]; then
	GO_URL=$GO_ARCH_PPC64LE
	NODEJS_URL=$NODEJS_ARCH_PPC64LE
else
	print_error "ARCH NO SUPPORT" && exit 1
fi

install_go
install_nodejs
install_grafana

remove_go
remove_node
remove_src_grafana