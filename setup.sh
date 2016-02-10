#!/bin/bash

set -e

OPTIND=1
SETUP_DIR=$PWD
HOME_DIR=$HOME

skip_install_packages=0
no_x=0
no_ruby=0
no_python=0
no_docker=0

required_packages=(
    python-software-properties
    software-properties-common
    ca-certificates
    apt-transport-https
    wget 
    curl 
    git
)
ruby_deps=(
    autoconf 
    bison 
    build-essential 
    libssl-dev 
    libyaml-dev 
    libreadline6-dev 
    libncurses5-dev 
    libffi-dev 
    libgdbm3 
    libgdbm-dev
    zlib1g-dev 
)
python_deps=(
    libssl-dev 
    libbz2-dev
    libreadline-dev 
    libsqlite3-dev 
    llvm 
    libncurses5-dev 
    libncursesw5-dev
    pep8
    pyflakes
    zlib1g-dev 
)
base_packages=(
    build-essential 
    emacs-goodies-el 
    libglib2.0-dev 
    silversearcher-ag 
)
x_packages=(
    fonts-inconsolata 
    libcanberra-gtk-module
    libgtk-3-dev 
    libx11-dev 
    libxft-dev 
    libxinerama-dev 
    libvte-dev 
    ttf-mscorefonts-installer
    emacs24 
)
no_x_packages=(
    emacs24-nox
)

install_packages() {
    sudo apt-get update && sudo apt-get install -y ${required_packages[@]}
    sudo add-apt-repository contrib
    sudo add-apt-repository non-free

    if [ $no_x -eq "0" ]; then
	packages="${base_packages[@]} ${x_packages[@]}"
    else
	packages="${base_packages[@]} ${no_x_packages[@]}"
    fi

    if [ $no_ruby -eq "0" ]; then
	packages="${packages[@]} ${ruby_deps[@]}"
    fi

    if [ $no_python -eq "0" ]; then
	packages="${packages[@]} ${python_deps[@]}"
    fi

    if [ $no_docker -eq "0" ]; then
	sudo apt-key adv --keyserver hkp://eu.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo "deb https://apt.dockerproject.org/repo debian-jessie main" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	packages="${packages[@]} docker-engine"
	sudo apt-get update
    fi

    sudo apt-get update && sudo apt-get install -y ${packages[@]}

    if [ $no_docker -eq "0" ]; then
	sudo service docker start
    fi
}

install_dwm() {
    if [ ! -d "dwm" ]; then
	git clone https://github.com/benwah/dwm.git ./dwm
    else
	git -C $SETUP_DIR/dwm pull
    fi
    cd $SETUP_DIR/dwm && make && sudo make install && cd $SETUP_DIR
    sudo ln -sf $SETUP_DIR/config/dwm.desktop /usr/share/xsessions/dwm.desktop
}

install_lilyterm() {
    if [ ! -d "lilyterm" ]; then
	git clone https://github.com/Tetralet/LilyTerm.git ./lilyterm
    else
	git -C $SETUP_DIR/lilyterm pull
    fi

    cd lilyterm && ./configure && make && sudo make install
    mkdir -p $HOME/.config/lilyterm
    ln -sf $SETUP_DIR/config/lilyterm.conf $HOME/.config/lilyterm/default.conf
}

install_rbenv() {
    if [ ! -d "$HOME/.rbenv" ]; then
	git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv
	git clone https://github.com/rbenv/ruby-build.git $HOME/.rbenv/plugins/ruby-build
    else
	git -C $HOME/.rbenv pull
	git -C $HOME/.rbenv/plugins/ruby-build pull
    fi
    
    cd $HOME/.rbenv && src/configure && make -C src

    if ! grep "rbenv" $HOME/.bashrc &> /dev/null; then 
	echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
	echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    fi
}

install_pyenv() {
    if [ ! -d "$HOME/.pyenv" ]; then
	git clone https://github.com/yyuu/pyenv.git $HOME/.pyenv 
    else
	git -C $HOME/.pyenv pull
    fi
    
    cd $HOME/.rbenv && src/configure && make -C src

    if ! grep "pyenv" $HOME/.bashrc &> /dev/null; then
	echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
	echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
	echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    fi
}

install_docker_compose() {
    if [ ! -e "/usr/local/bin/docker-compose" ]; then
	curl -L https://github.com/docker/compose/releases/download/1.6.0/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose > /dev/null
	sudo chmod +x /usr/local/bin/docker-compose
    fi
}

get_emacs_config() {
    if [ ! -d "$HOME/.emacs.d" ]; then
	git clone https://github.com/benwah/.emacs.d.git $HOME/.emacs.d
    else
	git -C $HOME/.emacs.d pull
    fi

    mkdir -p $HOME/.emacs.d/bin/
    if [ ! -e "$HOME/.emacs.d/bin/pychecker.sh" ]; then
	curl https://raw.githubusercontent.com/reinout/tools/f8d84f043e53c1dfc1e452cfaf00d3f831c9af7e/shell/pychecker.sh > $HOME/.emacs.d/bin/pychecker.sh
	chmod +x $HOME/.emacs.d/bin/pychecker.sh
    fi

    emacs --script $HOME/.emacs.d/init.el
}

show_help() {
    cat <<EOF 
-s     skip installing packages.
-r     skip rbenv installation and ruby build dependencies
-p     skip pyenv installation and python build dependencies
-d     skip docker installation
-n     installs only non-x packages
EOF
}

main() {
    echo -e "\n\e[36mInstalling packages...\e[0m"

    if [ $skip_install_packages -eq "0" ]; then
    	install_packages
    fi

    echo -e "\n\e[36mToggling color prompt...\e[0m"
    sed -i '/#force_color_prompt=yes/c\force_color_prompt=yes' $HOME/.bashrc

    if [ $no_x -eq "0" ]; then
    	echo -e "\n\e[36mInstalling DWM...\e[0m"
    	install_dwm

    	echo -e "\n\e[36mInstalling Lilyterm...\e[0m"
    	install_lilyterm
    fi

    if [ $no_docker -eq "0" ]; then
    	echo -e "\n\e[36mInstalling Docker-compose...\e[0m"
    	install_docker_compose
    fi

    if [ $no_ruby -eq "0" ]; then
    	echo -e "\n\e[36mInstalling rbenv...\e[0m"
    	install_rbenv
    fi

    if [ $no_python -eq "0" ]; then
    	echo -e "\n\e[36mInstalling pyenv...\e[0m"
    	install_pyenv
    fi
    
    echo -e "\n\e[36mDownloading emacs configuration...\e[0m"
    get_emacs_config

    echo -e "\n\e[32mDone!\e[0m"
}

while getopts ":h?snrpd" opt; do
    case "$opt" in
	h|\?)
	    show_help
	    exit 0
	    ;;
	s)  skip_install_packages="1"
	    ;;
	n)  no_x="1"
	    ;;
	r)  no_ruby="1"
	    ;;
	p)  no_python="1"
	    ;;
	d)  no_docker="1"
	    ;;
    esac
done

main
