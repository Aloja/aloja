CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR_TMP/on-premise.sh"


#vm_install_extra_packages() {
#  logger "Need to manually compile DSH"
#  compile_dsh
#}

install_ARM_JDK() {

  logger "Checking if to download and install Java for ARM"

  local JDK_folder="jdk1.7.0_60_ARM"

  vm_execute "[ ! -d ~/share/aplic/$JDK_folder ] &&
    {
      echo ' Dowloading Java JDK for AMR'
      cd ~/share/aplic
      wget -nv --no-cookies --no-check-certificate --header 'Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/7u60-b19/jdk-7u60-linux-arm-vfp-hflt.tar.gz -O jdk-7u60-linux-arm-vfp-hflt.tar.gz;
      tar -zxf jdk-7u60-linux-arm-vfp-hflt.tar.gz;
      mv jdk1.7.0_60 $JDK_folder;
    } || echo ' JDK already installed'"
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