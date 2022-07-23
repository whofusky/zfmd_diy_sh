#!/bin/bash
#
##############################################################################
#author:  fu.sky
#  
#   my wechat QR code:
#     
#   █▀▀▀▀▀▀▀██▀██▀▀▀███▀███▀▀▀▀▀▀▀█
#   █ █▀▀▀█ █▀▀ ▄ ▄▀ █▄█▄▄█ █▀▀▀█ █
#   █ █   █ ██▄ ▄██▄ ▄ ▄▄██ █   █ █
#   █ ▀▀▀▀▀ █▀▄▀█▀█▀▄ █▀▄ █ ▀▀▀▀▀ █
#   █▀▀▀█▀▀▀▀ ▄ ▀▄  █▄ █▀ ▀▀███▀███
#   ██▄█ ▄█▀██▀▄▄█ ▄▄ ████▄ ▀▀▄▀▀ █
#   █▀  ▀▄ ▀█ ██▄▀▄▄ ▀▄▄  ▀ ██▀█ ▀█
#   █ ▄▄  ▀▀▀▄▀█  ▄▀█  ██▄▄▄▀█ █▀ █
#   ██▄ █ ▀▀▄▄██▀▄  █▄ ▄▀  ▀▀█ █ ▀█
#   █▀▄▄█▀▄▀ ▄▄▀▄█ ▄██▄▄█▄▄ ██▄▄▀ █
#   █▀▄▄ ██▀█ ▄ ▄▀ ▄▄▀  █▀▀▀▀ ▄█▄██
#   █▀▀▀▀▀▀▀█ ▄▄   ▄█ ▄▄  █▀█ ▀▄  █
#   █ █▀▀▀█ █ ▀ ▀  ▄   ▀█ ▀▀▀ ▄█ ██
#   █ █   █ █▀ ▀▄▀ █▄▄█  ▄▀█▄ ▀▄▄ █
#   █ ▀▀▀▀▀ █   ▄█ ▀▀  ▄▄ █▀▀▀▀█ ▀█
#   ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
#   
#date  :  2022-07-15
#desc  :  在Kylin-PG-3.2操作系统环境部署负荷预测环境和程序
#
#  部署明细:
#      gmp-4.3.2 mpfr-2.4.2 mpc-1.0.1 gcc-5.4.0
#      libstdc++.so.6 从 libstdc++.so.6.0.13 升级到 libstdc++.so.6.0.21
#      cmake3.7.0
#      glog (可选)
#      stlf
#      tomcat 自启动
#      python3.6.8
#      系统编码:LANG="zh_CN.GBK"
#
########################################################################
#  
#  Note: The directory structure must be as follows
#  
#  .
#  ├── toInstallStlfBa.sh   #"去安装吧"自动部署脚本
#  ├── key_result_log.txt   #自动部署脚本生成的关键日志文件
#  ├── d5000
#  │   ├── include.tar.gz
#  │   ├── lib.zip
#  │   └── stlf
#  ├── local
#  │   ├── CMake-3.7.0.zip
#  │   ├── gcc-5.4.0.tar.gz
#  │   ├── glog
#  │   ├── gmp-4.3.2.tar.gz
#  │   ├── mpc-1.0.1.tar.gz
#  │   └── mpfr-2.4.2.tar.gz
#  ├── python
#  │   ├── Python-3.6.8.tgz
#  │   ├── fireTS-0.0.8-py3-none-any.whl
#  │   ├── joblib-1.1.0-py2.py3-none-any.whl
#  │   ├── numpy-1.19.5-cp36-cp36m-manylinux1_x86_64.whl
#  │   ├── pandas-1.1.5-cp36-cp36m-manylinux1_x86_64.whl
#  │   ├── patsy-0.5.2-py2.py3-none-any.whl
#  │   ├── pip-21.3.1-py3-none-any.whl
#  │   ├── python_dateutil-2.8.2-py2.py3-none-any.whl
#  │   ├── pytz-2022.1-py2.py3-none-any.whl
#  │   ├── scikit_learn-0.24.2-cp36-cp36m-manylinux1_x86_64.whl
#  │   ├── scipy-1.5.4-cp36-cp36m-manylinux1_x86_64.whl
#  │   ├── six-1.16.0-py2.py3-none-any.whl
#  │   ├── statsmodels-0.12.2-cp36-cp36m-manylinux1_x86_64.whl
#  │   ├── threadpoolctl-3.1.0-py3-none-any.whl
#  │   └── wheel-0.37.1-py2.py3-none-any.whl
#  └── stlf_c_10004.zip
#
##############################################################################
#

cityNmae="heihe"  #定义当前要部署的地市名称全拼
oldCityName="heilongjiang" #stlf源码CMakeLists.txt中的旧的地市名称
installGlogFlag=1       #是否安装glog: 1 安装，0 不安装


exeShName="$0"
baseDir="$(dirname $0)"

exePwd="$(pwd)"
#keyLog="${baseDir}/key_result_log.txt"  #定义输出结果日志
keyLog="${exePwd}/key_result_log.txt"  #定义输出结果日志


#第三方软件安装上级目录
prefixPDir="/usr/local"


#定义gcc升级需要的一些路径和文件
gcc_src_pdir="${baseDir}/local"
gmpVer="gmp-4.3.2"
gmpPFile="${gmpVer}.tar.gz"
mpfrVer="mpfr-2.4.2"
mpfrPFile="${mpfrVer}.tar.gz"
mpcVer="mpc-1.0.1"
mpcPFile="${mpcVer}.tar.gz"
gccVer="gcc-5.4.0"
gccPFile="${gccVer}.tar.gz"

#定义cmake升级需要的一些路径和文件
cmkVer="CMake-3.7.0"
cmkPFile="${cmkVer}.zip"

#定义glog安装路径
glogTDir="glog"

#定义安装stlf相关路径和文件
stlfSrcPDir="${baseDir}/d5000"
stlfSrcDir="${stlfSrcPDir}/stlf"
stlfIncd="include.tar.gz"
stlfSrcIcludeP="${stlfSrcPDir}/${stlfIncd}"
stlfLib="lib.zip"
stlfSrcLibP="${stlfSrcPDir}/${stlfLib}"
stlfCp="stlf_c_10004.zip"
stlfSrcCp="${baseDir}/${stlfCp}"

stlfDstPDir="/home/d5000/${cityNmae}"
stlfDstDir="${stlfDstPDir}/stlf"

#定义python3.6.8相关路径和文件
pySrcDir="${baseDir}/python"
pyVer="Python-3.6.8"
pySrcTar="${pyVer}.tgz"

pyDstDir="${prefixPDir}/python3"



tExpGcc="export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/${gmpVer}/lib:/usr/local/${mpcVer}/lib:/usr/local/${mpfrVer}/lib"

#记录关键信息到日志文件
function F_recordKeyLog()
{
    local inStr="$@"
    echo -e "$(date +%F_%T.%N):${inStr}"|tee -a "${keyLog}"
    return 0
}

#对Gcc升级需要的一些条件进行校验
function F_chkGccUpdate()
{
    #Is there an installation package ?

    local tmpDir="${gcc_src_pdir}/${gmpPFile}"
    if [ ! -e "${tmpDir}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:file[ ${tmpDir} ] not exist!"
        exit 1
    fi
    tmpDir="${gcc_src_pdir}/${mpfrPFile}"
    if [ ! -e "${tmpDir}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:file[ ${tmpDir} ] not exist!"
        exit 1
    fi
    tmpDir="${gcc_src_pdir}/${mpcPFile}"
    if [ ! -e "${tmpDir}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:file[ ${tmpDir} ] not exist!"
        exit 1
    fi
    tmpDir="${gcc_src_pdir}/${gccPFile}"
    if [ ! -e "${tmpDir}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:file[ ${tmpDir} ] not exist!"
        exit 1
    fi

    return 0
}

#对cmake安装需要的一些条件进行校验
function F_chkCmkPack()
{
    #Is there an installation package ?

    local tmpDir="${gcc_src_pdir}/${cmkPFile}"
    if [ ! -e "${tmpDir}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:file[ ${tmpDir} ] not exist!"
        exit 1
    fi
    return 0
}

#glog校验
function F_chkGlog()
{
    if [ "x${installGlogFlag}" != "x1" ];then
        return 0
    fi

    local tmpDir="${gcc_src_pdir}/${glogTDir}"
    if [ ! -d "${tmpDir}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:dir [ ${tmpDir} ] not exist!"
        exit 1
    fi
    return 0
}

#stlf部署校验
function F_chkStlf()
{

    if [ ! -d "${stlfSrcDir}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:dir [ ${stlfSrcDir} ] not exist!"
        exit 1
    fi
    if [ ! -d "${stlfDstPDir}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:dir [ ${stlfDstPDir} ] not exist!"
        exit 1
    fi
    if [ ! -f "${stlfSrcIcludeP}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:file [ ${stlfSrcIcludeP} ] not exist!"
        exit 1
    fi
    if [ ! -f "${stlfSrcLibP}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:file [ ${stlfSrcLibP} ] not exist!"
        exit 1
    fi
    if [ ! -f "${stlfSrcCp}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:file [ ${stlfSrcCp} ] not exist!"
        exit 1
    fi

    return 0
}

#python 3.6.8 部署校验
function F_chkPy368()
{

    if [ ! -d "${pySrcDir}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:dir [ ${pySrcDir} ] not exist!"
        exit 1
    fi

    local tFile="${pySrcDir}/${pySrcTar}"
    if [ ! -f "${tFile}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:file [ ${tFile} ] not exist!"
        exit 1
    fi

    return 0
}



#升级gcc依赖包共用函数
function F_updateGccDepPack()
{
    if [ $# -lt 2 ];then
        F_recordKeyLog "${FUNCNAME}:ERROR: input paras[$@] num not eq 2!\n"
        return 1
    fi

    local verStr="$1"
    local packStr="$2"
    local prefixStr="${prefixPDir}/${verStr}"
    if [ -d "${prefixStr}" ];then
        F_recordKeyLog "${FUNCNAME}:INFO:[ ${prefixStr} ] already exists, no need to upgrade!\n"
    else
        F_recordKeyLog "${FUNCNAME}:INFO:upgrade [ ${prefixStr} ] ...!\n"
        tar -zxvf ${packStr}
        cd ${verStr}
        if [ "${verStr}" = "gmp-4.3.2" ];then
            F_recordKeyLog "${FUNCNAME}:INFO:[ ./configure --prefix=${prefixStr} ]\n"
            ./configure --prefix=${prefixStr}
        elif [ "${verStr}" = "mpfr-2.4.2" ];then 
            F_recordKeyLog "${FUNCNAME}:INFO:[./configure --prefix=${prefixStr} --with-gmp=${prefixPDir}/${gmpVer} ]\n"
            ./configure --prefix=${prefixStr} --with-gmp=${prefixPDir}/${gmpVer}
        elif [ "${verStr}" = "mpc-1.0.1" ];then 
            F_recordKeyLog "${FUNCNAME}:INFO:[./configure --prefix=${prefixStr} --with-gmp=${prefixPDir}/${gmpVer} --with-mpfr=${prefixPDir}/${mpfrVer} ]\n"
            ./configure --prefix=${prefixStr} --with-gmp=${prefixPDir}/${gmpVer} --with-mpfr=${prefixPDir}/${mpfrVer}
        fi
        make
        make install
        cd ..
        F_recordKeyLog "${FUNCNAME}:INFO:upgrade [ ${prefixStr} ] end\n"
    fi
    return 0
}

#gcc 编辑添加环境变量
function F_addGccDepEnv()
{
    local edFile="/root/.bashrc"
    if [ ! -f "${edFile}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${edFile}] not exists\n"
        return 1
    fi

    local tnum=$(sed -n "/^\s*export\s\+LD_LIBRARY_PATH\s*=/{/${gmpVer}/p}" ${edFile}|wc -l)
    if [ ${tnum} -gt 0 ];then
        F_recordKeyLog "${FUNCNAME}:INFO:evn var [${tExpGcc}] already exists in file [${edFile}]\n"
        . "${edFile}"
        return 0
    fi
    echo "${tExpGcc}">>${edFile}

    . "${edFile}"
    local tmpStr="$(env|grep LD)"
    F_recordKeyLog "${FUNCNAME}:INFO:evn var add result [${tmpStr}]\n"
    return 0
}

#升级gcc
function F_updateGcc()
{
    cd "${exePwd}"
    cd ${gcc_src_pdir}
    F_recordKeyLog "${FUNCNAME}:cd ${gcc_src_pdir}!\n"

    #gmp
    F_updateGccDepPack "${gmpVer}" "${gmpPFile}"

    #mpfr
    F_updateGccDepPack "${mpfrVer}" "${mpfrPFile}"

    #mpc
    F_updateGccDepPack "${mpcVer}" "${mpcPFile}"

    F_addGccDepEnv

    local tmpStr
    local tmpStamp=$(date +%s)

    #gcc
    local prefixStr="${prefixPDir}/${gccVer}"
    if [ -d "${prefixStr}" ];then
        F_recordKeyLog "${FUNCNAME}:INFO:[ ${prefixStr} ] already exists, no need to upgrade!\n"

        #gcc -v >"${baseDir}/t.t"  2>&1
        #tmpStr="$(cat ${baseDir}/t.t)"
        #F_recordKeyLog "${FUNCNAME}:INFO:gcc -v:[${tmpStr}]"
        #g++ -v >"${baseDir}/t.t"  2>&1
        #tmpStr="$(cat ${baseDir}/t.t)"
        #F_recordKeyLog "${FUNCNAME}:INFO:g++ -v:[${tmpStr}]"
        #[ -e "${baseDir}/t.t" ] && rm -rf "${baseDir}/t.t"

        return 0
    else
        F_recordKeyLog "${FUNCNAME}:INFO:upgrade [ ${prefixStr} ] ...!\n"
        tar -zxvf ${gccPFile}
        cd ${gccVer}
        [ -d "gcc-build" ] && rm -rf "gcc-build" 
        mkdir gcc-build
        cd gcc-build

        F_recordKeyLog "${FUNCNAME}:INFO:[  ../configure --prefix=${prefixStr} --enable-threads=posix --disable-checking --disable-multilib --enable-languages=c,c++ --with-gmp=${prefixPDir}/${gmpVer} --with-mpfr=${prefixPDir}/${mpfrVer} --with-mpc=${prefixPDir}/${mpcVer}] "
        ../configure --prefix=${prefixStr} --enable-threads=posix --disable-checking --disable-multilib --enable-languages=c,c++ --with-gmp=${prefixPDir}/${gmpVer} --with-mpfr=${prefixPDir}/${mpfrVer} --with-mpc=${prefixPDir}/${mpcVer}

        F_recordKeyLog "${FUNCNAME}:INFO:upgrade [ ${prefixStr} ] configure end,begine make -j4!\n"
        make -j4
        F_recordKeyLog "${FUNCNAME}:INFO:upgrade [ ${prefixStr} ]  make -j4 end,begine make install!\n"
        make install
        F_recordKeyLog "${FUNCNAME}:INFO:upgrade [ ${prefixStr} ]  make install end!\n"
        cd ../../
        F_recordKeyLog "${FUNCNAME}:INFO:upgrade [ ${prefixStr} ] end\n"

        if [[ -f "/usr/local/${gccVer}/bin/gcc" && -f "/usr/local/${gccVer}/bin/g++" ]];then
            [ ! -d "/usr/gcc447backup" ] && mkdir /usr/gcc447backup
            mv /usr/bin/gcc /usr/gcc447backup/gcc.${tmpStamp}
            mv /usr/bin/g++ /usr/gcc447backup${tmpStamp}
            ln -s /usr/local/${gccVer}/bin/gcc /usr/bin/gcc
            ln -s /usr/local/${gccVer}/bin/g++ /usr/bin/g++
        else
            F_recordKeyLog "${FUNCNAME}:ERROR:upgrade [ ${prefixStr} ] fail!\n"
            [ -e "${prefixStr}" ] && rm -rf "${prefixStr}"
            exit 1
        fi

        F_recordKeyLog "${FUNCNAME}:INFO: update ${gccVer} result:"


        gcc -v >"${baseDir}/t.t"  2>&1
        tmpStr="$(cat ${baseDir}/t.t)"
        F_recordKeyLog "${FUNCNAME}:INFO:gcc -v:[${tmpStr}]"
        g++ -v >"${baseDir}/t.t"  2>&1
        tmpStr="$(cat ${baseDir}/t.t)"
        F_recordKeyLog "${FUNCNAME}:INFO:g++ -v:[${tmpStr}]"
        [ -e "${baseDir}/t.t" ] && rm -rf "${baseDir}/t.t"
    fi

    return 0
}

#升级libstdc++.so.6
function F_updatelibstdc()
{
    local tmpStr
    local soFile="/usr/lib64/libstdc++.so.6"
    local curLib=$(file ${soFile}|grep "link"|awk -F'`' '{print $NF}'|sed "s/'//g")
    F_recordKeyLog "${FUNCNAME}:INFO:cur version is:[${curLib}]"

    #find . -name "libstdc++*"|awk -F'/' '{print $NF}'|sort -t'.' -n -k5

    #find newest version
    cd "${exePwd}"
    if [ ! -e "${gcc_src_pdir}/${gccVer}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:dir [ ${gcc_src_pdir}/${gccVer} ] not exits!"
        exit 1
    fi
    cd "${gcc_src_pdir}/${gccVer}"

    local newLibP
    local newLib=$(find . -name "libstdc++.so.6*"|awk -F'/' '{print $NF}'|sort -t'.' -n -k5|tail -1)
    if [ -z "${newLib}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:in dir [ ${gcc_src_pdir}/${gccVer} ] not find libstdc++.so.6* !"
        exit 1
    fi

    if [ "x${curLib}" = "x${newLib}" ];then
        F_recordKeyLog "${FUNCNAME}:INFO:The current version [${curLib}] is the latest version"
    else
        tmpStr="$(strings ${soFile}|grep GLIBC)"
        F_recordKeyLog "${FUNCNAME}:INFO:${curLib} include[${tmpStr}]"
        F_recordKeyLog "${FUNCNAME}:INFO:find new version [${newLib}]"
        newLibP=$(find . -name "${newLib}"|tail -1)
        if [ -z "${newLibP}" ];then
            F_recordKeyLog "${FUNCNAME}:ERROR:in dir [ ${gcc_src_pdir}/${gccVer} ] not find ${newLib} !"
            exit 1
        else
            F_recordKeyLog "${FUNCNAME}:INFO:in dir [ ${gcc_src_pdir}/${gccVer} ] find [${newLibP}] !"
        fi

        cp "${newLibP}"  /usr/lib64/
        cd /usr/lib64/
        [ ! -d "backuplib" ] && mkdir backuplib
        mv libstdc++.so.6 backuplib/
        ln -s ${newLib} libstdc++.so.6
        tmpStr="$(strings ${soFile}|grep GLIBC)"
        F_recordKeyLog "${FUNCNAME}:INFO:${newLib} include[${tmpStr}]"
    fi

    return 0
}

#安装cmake
function F_installCmake()
{
    which cmake >/dev/null 2>&1
    local stat=$?
    if [ ${stat} -eq 0 ];then
        F_recordKeyLog "${FUNCNAME}:INFO:[ cmake ] already exists, no need to install!"
        cmake --version >"${baseDir}/t.t"  2>&1
        tmpStr="$(cat ${baseDir}/t.t)"
        F_recordKeyLog "${FUNCNAME}:INFO:[ cmake ] version [ ${tmpStr} ]!\n"
        [ -e "${baseDir}/t.t" ] && rm -rf "${baseDir}/t.t"
        return 0
    fi

    local tmpStr

    cd "${exePwd}"
    cd ${gcc_src_pdir}
    F_recordKeyLog "${FUNCNAME}:cd ${gcc_src_pdir}!\n"
    [ -d "${cmkVer}" ] && rm -rf "${cmkVer}"
    unzip ${cmkPFile}
    cd ${cmkVer}
    ./bootstrap
    make
    make install
    cmake --version >"${baseDir}/t.t"  2>&1
    tmpStr="$(cat ${baseDir}/t.t)"
    F_recordKeyLog "${FUNCNAME}:INFO:[ cmake ] install return[ ${tmpStr} ]!\n"
    [ -e "${baseDir}/t.t" ] && rm -rf "${baseDir}/t.t"

    return 0
}

#安装glog
function F_installGlog()
{
    if [ "x${installGlogFlag}" != "x1" ];then
        return 0
    fi
    local tFile="/usr/local/lib/libglog.a"

    if [ -e "${tFile}" ];then
        F_recordKeyLog "${FUNCNAME}:INFO:The file [${tFile} ]already exists, no need to install glog again!"
        return 0
    fi

    cd "${exePwd}"
    cd ${gcc_src_pdir}/${glogTDir}
    F_recordKeyLog "${FUNCNAME}:cd ${gcc_src_pdir}/${glogTDir}!"

    F_recordKeyLog "${FUNCNAME}:./autogen.sh!"
    [ ! -x "./autogen.sh" ] && chmod +x ./autogen.sh
    ./autogen.sh 
    F_recordKeyLog "${FUNCNAME}:./configure!"
    ./configure

    >"${baseDir}/t.t"

    F_recordKeyLog "${FUNCNAME}:make install!"
    make install|tee -a "${baseDir}/t.t"
    local tmpStr=$(grep -iA 2 "libraries have been installed in" "${baseDir}/t.t")
    F_recordKeyLog "${FUNCNAME}:INFO:install glog return [ ${tmpStr} ]!\n"
    [ -e "${baseDir}/t.t" ] && rm -rf "${baseDir}/t.t"

    return 0
}

#安装stlf
function F_installStlf()
{

    cd "${exePwd}"

    local haveFile="${stlfDstDir}/stlf_c/build/sys_single_fore/sys_single_fore"
    if [ -e "${haveFile}" ];then
        F_recordKeyLog "${FUNCNAME}:INFO:stlf is already installed!\n"
        return 0
    fi

    local dstSrcDir="${stlfDstPDir}/src"
    [ ! -d "${dstSrcDir}" ] && mkdir -p "${dstSrcDir}"

    cd ${stlfSrcPDir}
    F_recordKeyLog "${FUNCNAME}:cd ${stlfSrcPDir}!\n"

    F_recordKeyLog "${FUNCNAME}:tar -zxvf ${stlfIncd} -C ${dstSrcDir}"
    tar -zxvf "${stlfIncd}" -C "${dstSrcDir}"

    F_recordKeyLog "${FUNCNAME}:unzip -o ${stlfLib} -d ${stlfDstPDir}"
    unzip -o "${stlfLib}" -d "${stlfDstPDir}"

    F_recordKeyLog "${FUNCNAME}:cp -r stlf ${stlfDstPDir}"
    cp -r stlf  "${stlfDstPDir}" 

    F_recordKeyLog "${FUNCNAME}:cd .."
    cd ..
    F_recordKeyLog "${FUNCNAME}:cp ${stlfCp} ${stlfDstDir}"
    cp "${stlfCp}" "${stlfDstDir}"

    F_recordKeyLog "${FUNCNAME}:cd ${stlfDstDir}"
    cd "${stlfDstDir}"

    F_recordKeyLog "${FUNCNAME}:unzip -o ${stlfCp}"
    unzip -o "${stlfCp}"
    local tmkList="stlf_c/CMakeLists.txt"
    if [ ! -f "${tmkList}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${stlfSrcDir}/${tmkList}] not exist!\n"
        exit 1
    fi

    #modify stlf_c/CMakeLists.txt  
    local tnum=$(sed -n "/\b${oldCityName}\b/p" "${tmkList}"|wc -l)
    if [ ${tnum} -gt 0 ];then
        F_recordKeyLog "${FUNCNAME}:sed -i \"s/\b${oldCityName}\b/${cityNmae}/g\" ${tmkList}"
        sed -i "s/\b${oldCityName}\b/${cityNmae}/g" "${tmkList}"
    fi

    F_recordKeyLog "${FUNCNAME}:cd stlf_c"
    cd stlf_c
    F_recordKeyLog "${FUNCNAME}:mkdir build"
    [ ! -d build ] && mkdir build
    F_recordKeyLog "${FUNCNAME}:cd build"
    cd build
    F_recordKeyLog "${FUNCNAME}:cmake -D CMAKE_CXX_COMPILER=${prefixPDir}/${gccVer}/bin/g++  ../"
    cmake -D CMAKE_CXX_COMPILER=${prefixPDir}/${gccVer}/bin/g++  ../

    F_recordKeyLog "${FUNCNAME}:make"
    make

    local tmpStr=$(ls -lrt sys_single_fore/)

    F_recordKeyLog "${FUNCNAME}:INFO:install stlf return [ ${tmpStr} ]!\n"
    local tFile="sys_single_fore/sys_single_fore"
    if [ ! -e "${tFile}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:install stlf fail!\n"
        exit 1
    fi

    #modify cfg file
    local tcfgFile="../.stlf_config"
    if [ ! -e "${tcfgFile}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${tcfgFile}] not exist!\n"
        exit 1
    fi
    cp ../.stlf_config  sys_single_fore/
    tcfgFile="sys_single_fore/.stlf_config"
    if [ ! -e "${tcfgFile}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${tcfgFile}] not exist!\n"
        exit 1
    fi
    #sed  -i 's+^\s*logpath\s*=.*+logpath='${kk}'+g' t.txt
    tnum=$(sed -n "/^\s*logpath\s*=/{/\b${cityNmae}\b/p}" ${tcfgFile}|wc -l)
    local relLog="/home/d5000/${cityNmae}/stlf/stlf_c/log/"
    if [ ${tnum} -eq 0 ];then
        sed -i 's+^\s*logpath\s*=.*+logpath='${relLog}'+g' ${tcfgFile}
    fi


    return 0
}

#配置tomcat自启动
function F_addTomcatAutoStart()
{
    local edFile="/etc/rc.local"
    if [ ! -f "${edFile}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${edFile}] not exist!\n"
        exit 1
    fi
    local autoTomcatStr='
export JAVA_HOME=/home/d5000/heilongjiang/stlf/jdk1.8.0_161
export CATALINA_HOME=/home/d5000/heilongjiang/stlf/apache-tomcat-9.0.56
export PATH=$PATH:$JAVA_HOME/bin
sh $CATALINA_HOME/bin/startup.sh
    '
    autoTomcatStr=$(echo "${autoTomcatStr}"|sed "s/heilongjiang/${cityNmae}/g")

    local tmpStr
    tnum=$(sed -n "/^\s*export\s\s*JAVA_HOME\s*=/p" ${edFile}|wc -l)
    if [ ${tnum} -eq 0 ];then
        echo "${autoTomcatStr}" >kk.txt
        sed -i '$ r kk.txt' ${edFile}
        [ -e kk.txt ] && rm -rf kk.txt
        tmpStr=$(egrep "(^\s*export|^\s*sh)" ${edFile})
        F_recordKeyLog "${FUNCNAME}:INFO:file [${edFile}] add content is[${tmpStr}]!\n"
    else
        F_recordKeyLog "${FUNCNAME}:INFO:file [${edFile}] not need to added!\n"
        return 0
    fi

    return 0
}

function F_pip3instal()
{
    if [ $# -lt 1 ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:input para nums less 1!\n"
        exit 1
    fi
    local inP1="$1"
    if [ ! -e "${inP1}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${inP1} not exits!\n"
        exit 1
    fi

    F_recordKeyLog "${FUNCNAME}:INFO:pip3 install ${inP1}"
    pip3 install "${inP1}"
    return 0
}

#安装python3.6.8
function F_installPy368()
{
    which python36 >/dev/null 2>&1
    local stat=$?
    if [ ${stat} -eq 0 ];then
        F_recordKeyLog "${FUNCNAME}:INFO:python3.6.8 is already installed!\n"
        return 0
    fi

    local tmpStr
    cd "${exePwd}"
    cd "${pySrcDir}"
    F_recordKeyLog "${FUNCNAME}:INFO:cd ${pySrcDir}!\n"
    if [ ! -d "${pyDstDir}" ];then
        F_recordKeyLog "${FUNCNAME}:INFO:mkdir -p ${pyDstDir}"
        mkdir -p "${pyDstDir}"
    fi

    F_recordKeyLog "${FUNCNAME}:INFO:tar -zxvf ${pySrcTar} "
    [ -d "${pyVer}" ] && rm -rf "${pyVer}"
    tar -zxvf ${pySrcTar}
    
    if [ ! -d "${pyVer}" ];then
        F_recordKeyLog "ERROR:${FUNCNAME}:dir [ ${pyVer} ] not exist!"
        exit 1
    fi

    F_recordKeyLog "${FUNCNAME}:INFO:mv ${pyVer} ${pyDstDir} "
    local cmpilDir="${pyDstDir}/${pyVer}"
    [ -d "${cmpilDir}" ] && rm -rf "${cmpilDir}"
    mv ${pyVer} ${pyDstDir}

    F_recordKeyLog "${FUNCNAME}:INFO:cd ${cmpilDir}"
    cd ${cmpilDir}

    F_recordKeyLog "${FUNCNAME}:INFO:./configure  --enable-optimizations --prefix=${pyDstDir}"
    ./configure  --enable-optimizations --prefix=${pyDstDir}

    F_recordKeyLog "${FUNCNAME}:INFO:make -j8 && make altinstall"
    make -j8 && make altinstall

    local tFile="${pyDstDir}/bin/python3.6"
    if [ -f "${tFile}" ];then
        F_recordKeyLog "${FUNCNAME}:INFO:ln -s ${tFile} /usr/bin/python36"
        ln -s ${tFile} /usr/bin/python36
    else
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${tFile}] not exists!\n"
        exit 1
    fi

    tFile="${pyDstDir}/bin/pip3.6"
    if [ -f "${tFile}" ];then
        F_recordKeyLog "${FUNCNAME}:INFO:ln -s ${tFile} /usr/bin/pip3"
        ln -s ${tFile} /usr/bin/pip3
    else
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${tFile}] not exists!\n"
        exit 1
    fi

    cd "${exePwd}"
    cd "${pySrcDir}"
    F_recordKeyLog "${FUNCNAME}:INFO: cd ${exePwd};cd ${pySrcDir}!\n"

    #pip3 install
    F_pip3instal joblib-1.1.0-py2.py3-none-any.whl
    F_pip3instal numpy-1.19.5-cp36-cp36m-manylinux1_x86_64.whl
    F_pip3instal scipy-1.5.4-cp36-cp36m-manylinux1_x86_64.whl
    F_pip3instal threadpoolctl-3.1.0-py3-none-any.whl
    F_pip3instal scikit_learn-0.24.2-cp36-cp36m-manylinux1_x86_64.whl
    F_pip3instal six-1.16.0-py2.py3-none-any.whl
    F_pip3instal python_dateutil-2.8.2-py2.py3-none-any.whl
    F_pip3instal pytz-2022.1-py2.py3-none-any.whl
    F_pip3instal patsy-0.5.2-py2.py3-none-any.whl
    F_pip3instal pandas-1.1.5-cp36-cp36m-manylinux1_x86_64.whl
    F_pip3instal statsmodels-0.12.2-cp36-cp36m-manylinux1_x86_64.whl
    F_pip3instal fireTS-0.0.8-py3-none-any.whl
    F_pip3instal wheel-0.37.1-py2.py3-none-any.whl
    F_pip3instal pip-21.3.1-py3-none-any.whl

    #modify fireTS
    pip3 show fireTS
    tFile=${pyDstDir}/lib/python3.6/site-packages/fireTS/models.py
    if [ -f "${tFile}" ];then
        F_recordKeyLog "${FUNCNAME}:INFO:sed -i \"s/from\s\s*sklearn.metrics.regression\s\s*import\s\s*r2_score/from sklearn.metrics import r2_score/g\" ${tFile}"
        sed -i "s/from\s\s*sklearn.metrics.regression\s\s*import\s\s*r2_score/from sklearn.metrics import r2_score/g" ${tFile}
    else
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${tFile}] not exists!\n"
        exit 1
    fi

    python36 >t.t 2>&1 <<EOF
import wheel
import joblib
import numpy
import pandas
import scipy
import sklearn
import statsmodels
import fireTS
EOF

    tmpStr=$(cat t.t)
    F_recordKeyLog "${FUNCNAME}:INFO:python36 import return[ ${tmpStr} ]\n"
    [ -f t.t ] && rm -rf t.t

    return 0
}

#修改系统编码为zh_CN.GBK
function F_addSysLang()
{
    local edFile="/etc/profile"
    if [ ! -f "${edFile}" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:file [${edFile}] not exist!\n"
        exit 1
    fi

    local mdFlag=0

    local tLcall='export LC_ALL="zh_CN.GBK"'
    local tLang='export LANG="zh_CN.GBK"'

    local tnum=$(sed -n '/^\s*export\s\s*LC_ALL\s*=/{/zh_CN.GBK/p}' ${edFile}|wc -l)
    if [ ${tnum} -eq 0 ];then
        sed -i '/^\s*export\s\s*LC_ALL\s*=/d' ${edFile}
        echo "${tLcall}">> ${edFile}
        F_recordKeyLog "${FUNCNAME}:INFO:echo ${tLcall}>> ${edFile}"
        mdFlag=1
    fi

    tnum=$(sed -n '/^\s*export\s\s*LANG\s*=/{/zh_CN.GBK/p}' ${edFile}|wc -l)
    if [ ${tnum} -eq 0 ];then
        sed -i '/^\s*export\s\s*LANG\s*=/d' ${edFile}
        echo "${tLang}">> ${edFile}
        F_recordKeyLog "${FUNCNAME}:INFO:echo ${tLang}>> ${edFile}"
        mdFlag=1
    fi
    
    #modify /etc/sysconfig/i18n
    local t18nF="i18n"
    local t18Dir="/etc/sysconfig"
    tLang='LANG="zh_CN.GBK"'
    edFile="${t18Dir}/${t18nF}"
    if [ -f "${edFile}" ];then
        local ttmstap=$(date +%s)
        cd "${t18Dir}"
        tnum=$(sed -n '/^\s*LANG\s*=/{/zh_CN.GBK/p}' ${t18nF}|wc -l)
        if [ ${tnum} -eq 0 ];then
            cp ${t18nF} ${t18nF}.bak.${ttmstap}
            sed -i '/^\s*LANG\s*=/d' ${t18nF}
            echo "${tLang}">> ${t18nF}
            F_recordKeyLog "${FUNCNAME}:INFO:echo ${tLang}>> ${edFile}"
            mdFlag=1
        fi
        cd "${exePwd}"
    fi

    if [ ${mdFlag} -eq 0 ];then
        F_recordKeyLog "${FUNCNAME}:INFO:system coding [${tLang}] not need to add!\n"
    fi

    return 0
}

function F_check()
{
    local tUsr="$(id -un)"
    if [ "x${tUsr}" != "xroot" ];then
        F_recordKeyLog "${FUNCNAME}:ERROR:please execute as root user!\n"
        exit 1
    fi

    F_chkGccUpdate
    F_chkCmkPack
    F_chkGlog
    F_chkStlf
    F_chkPy368
    return 0
}

function F_install()
{
    #升级gcc
    F_updateGcc

    #升级libstdc++.so.6
    F_updatelibstdc

    #安装cmake
    F_installCmake

    #安装glog
    F_installGlog

    #安装stlf
    F_installStlf

    #配置tomcat自启动
    F_addTomcatAutoStart

    #install python3.6.8
    F_installPy368

    #修改系统编码为zh_CN.GBK
    F_addSysLang

    return 0
}

main()
{
    F_check
    F_install

    return 0
}


main


