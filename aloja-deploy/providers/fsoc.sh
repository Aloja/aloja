CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR_TMP/on-premise.sh"

vm_exists(){
  return 0
}

compile_dsh() {
  #test first if necessary
  vm_execute "[ ! $(dsh --version |grep 'Junichi') ] &&
  {
    cd /tmp;
    wget -nv http://www.netfort.gr.jp/~dancer/software/downloads/libdshconfig-0.20.13.tar.gz ;
    wget -nv http://www.netfort.gr.jp/~dancer/software/downloads/dsh-0.25.9.tar.gz ;

    cd /tmp;
    tar -zxf libdshconfig-0.20.13.tar.gz;
    cd libdshconfig-0.20.13;
    ./configure;
    make;
    sudo make install;

    cd /tmp;
    tar -zxf dsh-0.25.9.tar.gz;
    cd dsh-0.25.9;
    ./configure;
    make;
    sudo make install;
  }
"
}

vm_install_extra_packages() {
 logger "INFO: No extra packages to be installed for FSOC cluster"
}
