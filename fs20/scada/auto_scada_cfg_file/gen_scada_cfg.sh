#!/bin/bash
#
########################################################################
#
# @file    gen_scada_cfg.sh
# @brief   自动生成新版scada配置文件
# @details 根据提前填写的点表、did、及站等信息生成自动scada的配置文件
#
# @author  fu.sky
# @date    2021-12-29
# @version V10.01.000
# @prerequisites:
#             1. 将did csv文件放入imp_csv文件夹下
#                   文件名为: did.csv
#                   文件模板在:model/xlsx/did.csv
#             2. 将全局信息文件放入imp_csv文件夹下
#                   文件名为:frm.csv
#                   文件模板在:model/xlsx/frm.csv
#             3. 每个通道的点表配置放入imp_csv文件夹下
#                   文件名为:chn_0.csv ,其中0为实际的通道号,如果通道1则为1...
#                                       且必须从0开始多个文件中间不能跳号
#                   文件模板在:model/xlsx/chn_addr.csv
#
#
# @usage like: 
#         在脚本所有目录打开终端执行:./gen_scada_cfg.sh
#
# @history:
#
########################################################################
#

exShName="$0"

inExename="${exShName##*/}"

baseDir=$(dirname ${exShName})



##########sqlite3 bin file
mysqlite3="${baseDir}/bin/sqlite3"



##########tmp data dir
dtDname="data"
dataDir="${baseDir}/${dtDname}"
dataDbDir="${dataDir}/db"
dataSqlDir="${dataDir}/sql"
dataXmlDir="${dataDir}/xml"
dataCsvDir="${dataDir}/csv"




##########sqlite db file
sqliteDbFile="${dataDbDir}/scd_to_cfg_info.db"




##########create table sql file
dataCrtSqlF="${dataSqlDir}/create_table.sql"


##########tmp file
tmpDir="${baseDir}/tmp"
tmpFile="${tmpDir}/ttt.txt"
tmpFile1="${tmpDir}/ttt1.txt"
tmpFile2="${tmpDir}/ttt2.txt"
tmpFile3="${tmpDir}/ttt3.txt"
tmpFile4="${tmpDir}/ttt4.txt"


##########import csv file
csvDname="imp_csv"
csvDir="${baseDir}/${csvDname}"

frmCsvF="${csvDir}/frm.csv"
didCsvF="${csvDir}/did.csv"
chnCsvFPre="${csvDir}/chn_"

#doFrmCsvF="${dataCsvDir}/frm.csv"
#doDidCsvF="${dataCsvDir}/did.csv"
#doChnCsvFPre="${dataCsvDir}/chn_"

curDoDataFile="" #存储当前正在处理的data文件夹下的文件




##########model file
mdDname="model"
modDir="${baseDir}/${mdDname}"

xmlModDir="${modDir}/xml"
xmlModHeadF="${xmlModDir}/0head.xml"
xmlModDidF="${xmlModDir}/1did.xml"
xmlModAlgF="${xmlModDir}/2algorithm.xml"
xmlModStasF="${xmlModDir}/3sations.xml"
xmlModStaF="${xmlModDir}/3_1station.xml"
xmlModChnsF="${xmlModDir}/4chns.xml"
xmlModchnF="${xmlModDir}/4_1chn.xml"
xmlModSesF="${xmlModDir}/4_2session_modbus.xml"
xmlModPhyF="${xmlModDir}/4_3phy.xml"


sqlModDir="${modDir}/sql"
modPreCrtSqlF="${sqlModDir}/pre.sql" #初始化之前的sql脚本
modGblFile="${sqlModDir}/gbl.sql"   #全局信息表的建表语句
modChnFile="${sqlModDir}/chn_0.sql" #通道0需要的建表语句

xlsxModDir="${modDir}/xlsx"




##########result file
scdCfgFName="scdCfg.xml"
rstDir="${baseDir}/result"
resultFile="${rstDir}/${scdCfgFName}"
dataRstCfgF="${dataXmlDir}/${scdCfgFName}"




#快速生成站的点表(此方法一般适应于modbus 2个寄存器一个值的情况;
#    设置成0表示不用快速
#    设置成1表示用快速(此方法是用当前站第一个需要另外添加点地址的个数为所有要添加点地址个数的值)
g_quick_genAddrFlag=1

#对应的通道数量
#g_chnNums=1
g_chnNums=0




##########tables
tmpTableName="tmp_flag" #临时表:存储一些程序运行过程中产生的标识
didInfoTableName="g_did_info" #存储did名,did串,及did配置串(即did xml配置)
tmpDidMatchTblName="tmp_match_did"
frmInfoTblName="frm_info"  #存储风场名,通道号、通道ip等信息

addrInfPre="addr_info_"
staAddPre="station_addr_"


##########Global variable flag
g_num_of_records=0
g_did_name_match_flag=1


##########定义操作标识
OpSearch=0
OpUpdate=1








function F_rmExistFile() #Delete file if file exists
{
    [ $# -lt 1 ] && return 1

    local tFile="$1"
    while [ $# -gt 0 ]
    do
        tFile="$1"
        [ -e "${tFile}" ] && rm -rf "${tFile}"
        shift
    done

    return 0
}




function F_mkDir()
{
    [ $# -lt 1 ] && return 1

    local tDir="$1"
    while [ $# -gt 0 ]
    do
        tDir="$1"
        [ ! -d "${tDir}" ] && mkdir -p "${tDir}"
        shift
    done
    return 0
}




#将csv文件的标题头去掉,以便导入到sqlite3 表里
function F_delHeaderInCsv()
{
    [ $# -lt 1 ] && return 1

    local tFile="$1"

    while [ $# -gt 0 ]
    do
        tFile="$1"
        if [  -f "${tFile}" ];then
            sed -i '/^[a-zA-Z]\+/d' "${tFile}"
        fi
        shift
    done

    return 0
}




#判断sqlite数据文件中是否存在某个表
function F_IsThereATable() #return: 0 does not exist; 1 exist
{
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi

    local tTableName="$1"
    local tnaa=0

    tnaa=$(${mysqlite3} ${sqliteDbFile} "select count(1) from sqlite_master where type='table' and name='${tTableName}';")

    return ${tnaa}
}




function F_noFileAndExit()
{
    [ $# -lt 1 ] && return 1

    local tFile="$1"
    local noExistFlag=0

    while [ $# -gt 0 ]
    do
        tFile="$1"
        if [ ! -f "${tFile}" ];then
            noExistFlag=1
            echo "    ERROR: file [${tFile}] does not exist"
        fi
        shift
    done

    if [ ${noExistFlag} -eq 1 ];then
        exit 1
    fi

    return 0
}




#mk dir
function F_mkNeedDir()
{
    F_mkDir "${tmpDir}" "${rstDir}"
    F_mkDir "${dataDbDir}" "${dataSqlDir}" "${dataXmlDir}" "${dataCsvDir}"
    return 0
}




function F_preChkFileExist()
{

    echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:Initially verify the existence of some files"

    #local i
    #F_noFileAndExit "${sqliteDbFile}"
    
    #check sqlite3 exe
    F_noFileAndExit "${mysqlite3}"

    #check fix xml model file
    #F_noFileAndExit "${xmlModDirF[@]}"
    F_noFileAndExit "${xmlModHeadF}" "${xmlModDidF}" "${xmlModAlgF}" "${xmlModStasF}" "${xmlModStaF}" "${xmlModChnsF}" "${xmlModchnF}" "${xmlModSesF}" "${xmlModPhyF}" 

    #check fix import csv file
    F_noFileAndExit "${frmCsvF}" "${didCsvF}"

    #check mod sql file
    F_noFileAndExit "${modPreCrtSqlF}" "${modGblFile}" "${modChnFile}"

    return 0
}




#检验各通道的点表csv文件是否存在
function F_chkChnCsvFileExist()
{
    echo "$(date +%F_%T.%N):${FUNCNAME}:INFO"

    local i; local tFile;

    for ((i=0;i<${g_chnNums};i++))
    do
        tFile="${chnCsvFPre}${i}.csv"
        F_noFileAndExit "${tFile}"
    done
    return 0
}




function F_noTableAndExit()
{
    [ $# -lt 1 ] && return 1

    local tTbl="$1"
    local noExistFlag=0
    local retCmdStat=0

    while [ $# -gt 0 ]
    do
        tTbl="$1"
        F_IsThereATable "${tTbl}"
        retCmdStat=$?

        if [ "${retCmdStat}x" != "1x" ];then
            noExistFlag=1
            echo -e "\n\tERROR:${FUNCNAME}:Table [${tTbl}] does not exist in [${sqliteDbFile}]!\n"
        fi

        shift
    done

    if [ ${noExistFlag} -eq 1 ];then
        exit 1
    fi

    return 0
}




function F_chkTblExist()
{
    echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:Check if the table exists!"

    F_noTableAndExit "${tmpTableName}" "${didInfoTableName}" "${tmpDidMatchTblName}" "${frmInfoTblName}"

    local tTbl1; local tTbl2; local i;
    for ((i=0;i<${g_chnNums};i++))
    do
        tTbl1="${addrInfPre}${i}"
        tTbl2="${staAddPre}${i}"
        F_noTableAndExit "${tTbl1}" "${tTbl2}"
    done

    return 0
}




#从 model文件夹下对应文件拷贝到data文件夹下,并将data文件夹下文件名临时赋值给curDoDataFile
function F_cpModF2Data()
{
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi
    local inFile="$1"
    local tPath=$(echo "${inFile%/*}"|sed "s+/${mdDname}/+/${dtDname}/+g")
    F_mkDir "${tPath}"
    #curDoDataFile=$(echo "${inFile}"|sed "s+/${mdDname}/+/${dtDname}/+g")
    curDoDataFile="${tPath}/${inFile##*/}"
    cp -a "${inFile}" "${curDoDataFile}"
    return 0
}




#从 imp_csv文件夹下对应文件拷贝到data文件夹下,并将data文件夹下文件名临时赋值给curDoDataFile
function F_cpCsvF2Data()
{
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi
    local inFile="$1"
    local tPath=$(echo "${inFile%/*}/csv"|sed "s+/${csvDname}/+/${dtDname}/+g")
    F_mkDir "${tPath}"
    #curDoDataFile=$(echo "${inFile}"|sed "s+/${csvDname}/+/${dtDname}/+g")
    curDoDataFile="${tPath}/${inFile##*/}"

    local tchSet=$(file  --mime-encoding "${inFile}"|awk '{print $2}')
    tchSet="${tchSet%%-*}"
    if [ "${tchSet}" == "iso" ];then
        [ -e "${curDoDataFile}" ] && rm -rf "${curDoDataFile}"
        iconv -f gbk -t utf8 "${inFile}" -o "${curDoDataFile}"
    else
        cp -a "${inFile}" "${curDoDataFile}"
    fi
    F_delHeaderInCsv "${curDoDataFile}"
    return 0
}




#检查系统是否有必要的系统命令
function F_chkCmd()
{
    [ $# -lt 1 ] && return 1

    local tCmd="$1"
    while [ $# -gt 0 ]
    do
        tCmd="$1"
        which ${tCmd} >/dev/null 2>&1
        if [ $? -ne 0 ];then
            echo -e "\n${FUNCNAME}:ERROR:no ${tCmd} commands in system!"
            exit 1
        fi
        shift
    done

    return 0
}




#需要提前做的操作:建立风场信息及取得通道个数等
function F_preDo()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."

    F_mkNeedDir
    F_preChkFileExist

    [ ! -x "${mysqlite3}" ] && chmod u+x "${mysqlite3}"
    [ -e "${sqliteDbFile}" ] && mv "${sqliteDbFile}" "${sqliteDbFile}.bak"

    F_cpModF2Data "${modPreCrtSqlF}"

    echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:${mysqlite3} ${sqliteDbFile} \".read ${curDoDataFile}\""
    ${mysqlite3} ${sqliteDbFile} ".read ${curDoDataFile}"


    F_cpCsvF2Data "${frmCsvF}"

    echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:${mysqlite3} ${sqliteDbFile} \".import ${curDoDataFile} ${frmInfoTblName} --csv\""
    ${mysqlite3} ${sqliteDbFile} ".import ${curDoDataFile} ${frmInfoTblName} --csv"

    g_chnNums=$(${mysqlite3} ${sqliteDbFile} "select count(1) from ${frmInfoTblName} where chn_no<>'';")

    #echo "g_chnNums=[${g_chnNums}]"
    if [ ${g_chnNums} -lt 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}: According to the content of the file[${curDoDataFile}]: g_chnNums=[${g_chnNums}] \n"
        exit 1
    fi

    #F_chkChnCsvFileExist
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end\n"

    return 0
}




#根据通道个数生成data/sql文件夹下的create_table.sql文件内容
#  然后根据sql语句生成数据表
function F_genCrtSqlTbl()
{
    echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:Generate [${dataCrtSqlF}] file content"

    cp -a "${modGblFile}" "${dataCrtSqlF}"

    #将通道0需要建表的sql追加到 create_table.sql
    cat "${modChnFile}" >> "${dataCrtSqlF}"

    #将其他通道需要建表的sql追加到 create_table.sql
    local i=1;
    for ((i=1;i<${g_chnNums};i++))
    do
        sed "s/_0/_${i}/g" "${modChnFile}" >> "${dataCrtSqlF}"
    done

    echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:${mysqlite3} ${sqliteDbFile} \".read ${dataCrtSqlF}\""

    ${mysqlite3} ${sqliteDbFile} ".read ${dataCrtSqlF}"

    return 0
}




#导入配置的csv文件信息
function F_impCfgcsvFile()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."

    #import did.csv
    F_cpCsvF2Data "${didCsvF}"
    local tDomNum=$(tail -1 "${curDoDataFile}" |awk -F',' '{print NF}')
    if [ ${tDomNum} -eq 2 ];then
        sed -i 's/$/,/g' "${curDoDataFile}"
    fi

    echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:import ${curDoDataFile} to tbl [${didInfoTableName}]"
    ${mysqlite3} ${sqliteDbFile} ".import ${curDoDataFile} ${didInfoTableName} --csv"

    #import 各个通道的点表信息
    local i; local tTbl; local tFile;
    for ((i=0;i<${g_chnNums};i++))
    do
        tFile="${chnCsvFPre}${i}.csv"
        tTbl="${addrInfPre}${i}"

        F_cpCsvF2Data "${tFile}"

        echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:import ${curDoDataFile} to tbl [${tTbl}]"
        ${mysqlite3} ${sqliteDbFile} ".import ${curDoDataFile} ${tTbl} --csv"
    done

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end\n"

    return 0
}




#初始化及校验函数
function F_init()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: --------------------in ..."

    F_chkCmd "iconv" "bc"
    F_preDo
    F_chkChnCsvFileExist

    F_genCrtSqlTbl

    F_chkTblExist

    F_impCfgcsvFile

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: --------------------end\n"

    return 0
}




#获取输入参数对应数据表的记录总数
function F_retNumOfDataInTable()
{
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi

    local retCmdStat=0
    local tTableName="$1"
    F_IsThereATable "${tTableName}"
    retCmdStat=$?

    if [ "${retCmdStat}x" != "1x" ];then
        echo -e "\n\tERROR:${FUNCNAME}:Table [${tTableName}] does not exist!\n"
        exit 1
    fi

    g_num_of_records=$(${mysqlite3} ${sqliteDbFile} "select count(1) from ${tTableName};")
    return 0
}




#设置g_did_info表的cfg_str字段的值
function F_setDidInfo_cfgStr()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."
    ${mysqlite3} ${sqliteDbFile} "update ${didInfoTableName} set cfg_str='<dataId didVal=\"'||did_bin_val||'\" serialNo=\"'||rowid||'\" didName=\"'||did_name||'\"/>';"
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end\n"
    return 0
}




#根据addr_info_*表的值生成station_addr_*表的值
function F_genOneStatAddrCnt()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi
    local tblNo="$1"

    local isNum=$(echo "${tblNo}"|sed -n '/^[0-9]\+$/p'|wc -l)
    if [ ${isNum} -eq 0 ];then
        echo -e "\n\tERROR:${FUNCNAME}:parameter 1 should be a number! \n"
        exit 1
    fi

    if [ ${tblNo} -ge ${g_chnNums} ];then
        echo -e "\n\tERROR:${FUNCNAME}:The value of parameter 1 cannot be greater than or equal to ${g_chnNums}!\n"
        exit 1
    fi

    local srcTbl="${addrInfPre}${tblNo}"
    local dstTbl="${staAddPre}${tblNo}"

    echo "$(date +%F_%T.%N):${FUNCNAME}:[${srcTbl}]->[${dstTbl}]"

    #delete old records
    ${mysqlite3} ${sqliteDbFile} "delete from ${dstTbl};"


    local startm=$(date +%s)
    #insert init addr
    ${mysqlite3} ${sqliteDbFile} "insert into ${dstTbl} select addr_val,addr_type,addr_name,'<pntAddr remoteAddr=\"'||addr_val||'\" localAddr=\"'||(addr_val+(offset_to_local))||'\" name=\"'||addr_name||'\" type=\"'||addr_type||'\" startBit=\"0\" bitLength=\"16\" codCoefficient=\"1\" pntDataLng=\"16\" offset=\"0\" unitDesc=\"\" encoding=\"0\"/>' from ${srcTbl};"


    local costtm; local endtm;

    #local endtm=$(date +%s)
    #local costtm=$(echo "${endtm} - ${startm}"|bc)
    #echo "$(date +%F_%T.%N):${FUNCNAME}:use [ ${costtm} ] seconds"

    if [ ${g_quick_genAddrFlag} -eq 1 ];then
        local tAdNum=$(${mysqlite3} ${sqliteDbFile} "select append_add_num from ${srcTbl} where append_add_num>0 limit 1;")
        local i
        for ((i=1;i<=${tAdNum};i++))
        do
            ${mysqlite3} ${sqliteDbFile} "insert into ${dstTbl} select (addr_val+${i}),addr_type,addr_name,'<pntAddr remoteAddr=\"'||(addr_val+${i})||'\" localAddr=\"'||(addr_val+${i}+(offset_to_local))||'\" name=\"'||addr_name||'\" type=\"'||addr_type||'\" startBit=\"0\" bitLength=\"16\" codCoefficient=\"1\" pntDataLng=\"16\" offset=\"0\" unitDesc=\"\" encoding=\"0\"/>' from ${srcTbl} where append_add_num>0;"
        done

    else
        #>ftest.sql

        #insert other addr
        local trowid; local taddnum; local i;
        ${mysqlite3} -column  ${sqliteDbFile} "select rowid,append_add_num from ${srcTbl} where append_add_num>0 order by (addr_val+0) asc;"|while read trowid taddnum
        do
            for ((i=1;i<=${taddnum};i++))
            do
                #echo "insert into ${dstTbl} select (addr_val+${i}),addr_type,addr_name,'<pntAddr remoteAddr=\"'||(addr_val+${i})||'\" localAddr=\"'||(addr_val+${i}+(offset_to_local))||'\" name=\"'||addr_name||'\" type=\"'||addr_type||'\" startBit=\"0\" bitLength=\"16\" codCoefficient=\"1\" pntDataLng=\"16\" offset=\"0\" unitDesc=\"\" encoding=\"0\"/>' from ${srcTbl} where rowid=${trowid};">>ftest.sql

                ${mysqlite3} ${sqliteDbFile} "insert into ${dstTbl} select (addr_val+${i}),addr_type,addr_name,'<pntAddr remoteAddr=\"'||(addr_val+${i})||'\" localAddr=\"'||(addr_val+${i}+(offset_to_local))||'\" name=\"'||addr_name||'\" type=\"'||addr_type||'\" startBit=\"0\" bitLength=\"16\" codCoefficient=\"1\" pntDataLng=\"16\" offset=\"0\" unitDesc=\"\" encoding=\"0\"/>' from ${srcTbl} where rowid=${trowid};"

            done
        done

        #${mysqlite3} ${sqliteDbFile} ".read ftest.sql"
    fi

    endtm=$(date +%s)
    costtm=$(echo "${endtm} - ${startm}"|bc)
    echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:It takes [${costtm}] seconds to generate the content of the [${dstTbl}] table"
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end\n"

    return 0
}




#设置tmp_flag表的did_name_match_flag字段的值
function F_setDidMatchFlag() 
{
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi

    local tFlag="$1"

    local retCmdStat=0

    F_retNumOfDataInTable "${tmpTableName}"
    if [ ${g_num_of_records} -eq 0 ];then
        ${mysqlite3} ${sqliteDbFile} "insert into ${tmpTableName} values(${tFlag});"
    elif [ ${g_num_of_records} -eq 1 ];then
        ${mysqlite3} ${sqliteDbFile} "update ${tmpTableName} set did_name_match_flag=${tFlag} where did_name_match_flag<>${tFlag};"
    else
        ${mysqlite3} ${sqliteDbFile} "delete from ${tmpTableName} where rowid>1;"
        ${mysqlite3} ${sqliteDbFile} "update ${tmpTableName} set did_name_match_flag=${tFlag} where did_name_match_flag<>${tFlag};"
    fi

    return 0
}




#获取tmp_flag表的did_name_match_flag字段的值
function F_getMatchDidFlag()
{
    g_did_name_match_flag=$(${mysqlite3} ${sqliteDbFile} "select did_name_match_flag from ${tmpTableName};"|head -1)
    return 0
}




#0: 校验addr_info_*的表中需要配置的物理量是否有匹配的did
#1: 更新addr_info_*的表中*_val_*mi原来是非空(即需要配置物理)的值在原来值结尾添加上"#配置的did rowid"
function F_opPhy_xdid_oneTbl()
{
    if [ $#  -ne 3 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 3 \n"
        exit 1
    fi

    local tTableName="$1"
    local tOpFlag="$2"  #0:search match; 1 update
    local tType="$3"    #x: x_val; rtv: rtv_val; avg: avg_val; sdv: sdv_val;

    if [[ "x0" != "x${tOpFlag}" && "x1" != "x${tOpFlag}" ]];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter 2 must one of \"0,1\" \n"
        exit 2
    fi
    if [[ "xx" != "x${tType}" && "xrtv" != "x${tType}" && "xavg" != "x${tType}" && "xsdv" != "x${tType}" ]];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter 3 must one of \"x,rtv,avg,sdv\" \n"
        exit 2
    fi

    local fixMins="1 5 15"

    local tColumn ; local tMinName; local suffixName="";
    local preColName;
    if [[ "xx" = "x${tType}" ]];then
        preColName="x_val"
        suffixName="''"
    elif [[ "xrtv" = "x${tType}" ]];then
        preColName="rtv_val"
        suffixName="'实时值'"
    elif [[ "xavg" = "x${tType}" ]];then
        preColName="avg_val"
        suffixName="'平均值'"
    elif [[ "xsdv" = "x${tType}" ]];then
        preColName="sdv_val"
        suffixName="'标准差值'"
    fi


    local tOpName=""
    if [ ${tOpFlag} -eq ${OpSearch} ];then  #search
        tOpName="查询是否有匹配的did"
    else
        tOpName="在对应域添加匹配的did序号"
    fi


    for min_No in ${fixMins}
    do
        if [ "x1" = "x${min_No}" ];then
            tColumn="${preColName}_1mi"
            tMinName="'1分钟'"
        elif [ "x5" = "x${min_No}" ];then 
            tColumn="${preColName}_5mi"
            tMinName="'5分钟'"
        elif [ "x15" = "x${min_No}" ];then 
            if [[ "xrtv" = "x${tType}" ]];then 
                #无15分钟的实时值
                continue
            fi
            tColumn="${preColName}_15mi"
            tMinName="'15分钟'"
        fi

        #echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:${tOpName}:tTableName=[${tTableName}],tColumn=[${tColumn}],tMinName=[${tMinName}]"

        local  tnum=0
        local tnaa

        if [ ${tOpFlag} -eq ${OpSearch} ];then  #search
            ${mysqlite3} ${sqliteDbFile} "select ${tMinName}||did_core_name0||did_core_name1||did_core_name2||${suffixName}||trim(did_suffix_name) from ${tTableName} where trim(${tColumn})<>'';"|while read tnaa; 
            do 
                #echo "$(date +%F_%T.%N):---search:[${tnaa}]---"; 
                tnum=$(${mysqlite3} ${sqliteDbFile} "select rowid,* from ${didInfoTableName} where did_name=\"${tnaa}\";" |wc -l)
                if [ ${tnum} -eq 0 ];then
                    echo ""; 
                    echo "$(date +%F_%T.%N):${FUNCNAME}:ERROR:[${tnaa}] ----> not find"; 
                    echo ""; 

                    F_setDidMatchFlag 0
                fi
            done
        else #update 

            ${mysqlite3} ${sqliteDbFile} "delete from ${tmpDidMatchTblName};"

            ${mysqlite3} ${sqliteDbFile} "insert into ${tmpDidMatchTblName} select a.rowid,trim(a.${tColumn})||'#'||b.rowid from ${tTableName} a,${didInfoTableName} b where trim(a.${tColumn})<>'' and b.did_name=${tMinName}||a.did_core_name0||a.did_core_name1||a.did_core_name2||${suffixName}||trim(did_suffix_name);"

            ${mysqlite3} ${sqliteDbFile} "update ${tTableName} set ${tColumn}=(select x_val_str from ${tmpDidMatchTblName} where addr_rowid=${tTableName}.rowid) where EXISTS (select x_val_str from ${tmpDidMatchTblName} where addr_rowid=${tTableName}.rowid);"

        fi
    done

    return 0
}




#检验配置的点表中是否有找不到did配置的，如果找不到则退出整个程序
function F_search_xdid()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."
    local tTbl; local i;

    for ((i=0;i<${g_chnNums};i++))
    do
        tTbl="${addrInfPre}${i}"
        echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:[${i}/${g_chnNums}] tTbl=[${tTbl}]"
        F_opPhy_xdid_oneTbl ${tTbl} ${OpSearch} "x"
        F_opPhy_xdid_oneTbl ${tTbl} ${OpSearch} "rtv"
        F_opPhy_xdid_oneTbl ${tTbl} ${OpSearch} "avg"
        F_opPhy_xdid_oneTbl ${tTbl} ${OpSearch} "sdv"
    done

    F_getMatchDidFlag
    #echo "g_did_name_match_flag=[${g_did_name_match_flag}]"
    if [ ${g_did_name_match_flag} -eq 0 ];then
        exit 1
    fi
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end\n"

    return 0
}




#更新点表中物理量配置字段,在原字段值基础上添加匹配did的rowid
#(注意在调用此函数之前需要调用 F_search_xdid 进行校验没有错）
function F_update_xdid()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."
    local tTbl; local i;

    for ((i=0;i<${g_chnNums};i++))
    do
        tTbl="${addrInfPre}${i}"
        echo "$(date +%F_%T.%N):${FUNCNAME}:INFO:[${i}/${g_chnNums}] tTbl=[${tTbl}]"
        F_opPhy_xdid_oneTbl ${tTbl} ${OpUpdate} "x"
        F_opPhy_xdid_oneTbl ${tTbl} ${OpUpdate} "rtv"
        F_opPhy_xdid_oneTbl ${tTbl} ${OpUpdate} "avg"
        F_opPhy_xdid_oneTbl ${tTbl} ${OpUpdate} "sdv"
    done
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end\n"

    return 0
}




#将所有通道进行处理:根据addr_info_*表的值生成station_addr_*表的值
function F_genStationAddrCnt()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."
    local i;

    for ((i=0;i<${g_chnNums};i++))
    do
        F_genOneStatAddrCnt  "${i}"
    done
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end\n"
    return 0
}



#为生成最终的配置文件准备必要的数据
function F_prepareData()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: --------------------in ..."
    F_setDidMatchFlag 1

    F_search_xdid
    F_update_xdid
    F_genStationAddrCnt
    F_setDidInfo_cfgStr
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: --------------------end\n"
    return 0

}




#设置xml结点某个属性的值
function F_setXmlNodeAttrVal()
{
    if [[ $#  -ne 4 && $# -ne 5 ]];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 4/5 \n"
        exit 1
    fi

    local tFile="$1"
    local tNodName="$2"
    local tKey="$3"
    local tVal="$4"
    local tLinNo=""
    if [ $# -eq 5 ];then
        tLinNo="$5"
    fi

    if [ ! -f "${tFile}" ];then
        echo -e "\n\tERROR:${FUNCNAME}:file[${tFile}] not exist! \n"
        exit 1
    fi

    local tnum=$(sed -n "/^\s*<\s*${tNodName}\b/p" "${tFile}"|wc -l)
    if [ ${tnum} -eq 0 ];then
        echo -e "\n\tERROR:${FUNCNAME}:in file[${tFile}] xml node <${tNodName} not exist! \n"
        exit 1
    fi

    tnum=$(sed -n "/^\s*<\s*${tNodName}\b/{/\b${tKey}\s*=\s*/p}" "${tFile}"|wc -l)
    if [ ${tnum} -eq 0 ];then  #不存在tNodName结点的tKey属性则添加tKey属性
        if [ -z "${tLinNo}" ];then
            sed -i "s/^\s*<\s*${tNodName}\b/& ${tKey}=\"${tVal}\"/g" "${tFile}"
        else
            sed -i "${tLinNo} {s/^\s*<\s*${tNodName}\b/& ${tKey}=\"${tVal}\"/g}" "${tFile}"
        fi
    else
        if [ -z "${tLinNo}" ];then
            sed -i "/^\s*<\s*${tNodName}\b/{s/\b${tKey}\s*=\s*\"[^\"]*\"/${tKey}=\"${tVal}\"/g}" "${tFile}"
        else
            sed -i "${tLinNo} {/^\s*<\s*${tNodName}\b/{s/\b${tKey}\s*=\s*\"[^\"]*\"/${tKey}=\"${tVal}\"/g}}" "${tFile}"
        fi
    fi

    return 0
}




#设置xml结点的值
function F_setXmlNodeVal()
{
    if [[ $#  -ne 3 && $# -ne 4 ]];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 3/4 \n"
        exit 1
    fi

    local tFile="$1"
    local tNodName="$2"
    local tVal="$3"
    local tLinNo=""
    if [ $# -eq 4 ];then
        tLinNo="$4"
    fi

    if [ ! -f "${tFile}" ];then
        echo -e "\n\tERROR:${FUNCNAME}:file[${tFile}] not exist! \n"
        exit 1
    fi

    local tnum=$(sed -n "/^\s*<\s*${tNodName}\b/p" "${tFile}"|wc -l)
    if [ ${tnum} -eq 0 ];then
        echo -e "\n\tERROR:${FUNCNAME}:in file[${tFile}] xml node <${tNodName} not exist! \n"
        exit 1
    fi

    if [ -z "${tLinNo}" ];then
        sed -i "s/<\s*${tKey}\s*>[^>]*<\s*\/\s*${tKey}\s*>/<${tKey}>${tVal}<\/${tKey}>/" ${tFile} 
    else
        sed -i "${tLinNo}{s/<\s*${tKey}\s*>[^>]*<\s*\/\s*${tKey}\s*>/<${tKey}>${tVal}<\/${tKey}>/}" ${tFile} 
    fi

    return 0
}




function F_addXmlHead()
{
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."

    cp -a "${xmlModHeadF}" "${dataRstCfgF}"
    local tTime=$(date +%F_%T)
    local dataLocIp; local dataRmtIp; local frmName;
    local tmpStr=$(${mysqlite3} ${sqliteDbFile} "select frm_name,data_local_ip,data_rmt_ip from ${frmInfoTblName} where frm_name<>'' limit 1;")
    frmName=$(echo "${tmpStr}"|cut -d'|' -f 1)
    dataLocIp=$(echo "${tmpStr}"|cut -d'|' -f 2)
    dataRmtIp=$(echo "${tmpStr}"|cut -d'|' -f 3)

    sed -i "s/xxxxxxxxxx/${frmName}/g" "${dataRstCfgF}" 
    sed -i "s/0000-00-00/${tTime}/g" "${dataRstCfgF}" 
    F_setXmlNodeAttrVal "${dataRstCfgF}" "dataInIP" "lcalIp" "${dataLocIp}"
    F_setXmlNodeAttrVal "${dataRstCfgF}" "dataInIP" "rmtIp" "${dataRmtIp}"
    F_setXmlNodeAttrVal "${dataRstCfgF}" "dataOutIP" "lcalIp" "${dataLocIp}"
    F_setXmlNodeAttrVal "${dataRstCfgF}" "dataOutIP" "rmtIp" "${dataRmtIp}"
    F_setXmlNodeAttrVal "${dataRstCfgF}" "stationNum" "value" "${g_chnNums}"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end"

    return 0
}




function F_addDidCfg()
{
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."

    ${mysqlite3} ${sqliteDbFile} "select cfg_str from ${didInfoTableName} order by rowid asc;" >"${tmpFile}"

    sed -i 's/^/        /g' "${tmpFile}"

    cat "${xmlModDidF}">>"${dataRstCfgF}" 
    sed -i "/^\s*<\s*didInfo\s*>/ r ${tmpFile}" "${dataRstCfgF}"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end"

    return 0
}




function F_addAlgCfg()
{
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."
    cat "${xmlModAlgF}">>"${dataRstCfgF}" 
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end"
    return 0
}




function F_addOneStationCfg()
{
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi
    local tChnNo="$1"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: in ...chnNo=[${tChnNo}]"

    local isNum=$(echo "${tChnNo}"|sed -n '/^[0-9]\+$/p'|wc -l)
    if [ ${isNum} -eq 0 ];then
        echo -e "\n\tERROR:${FUNCNAME}:parameter 1 should be a number! \n"
        exit 1
    fi

    if [ ${tChnNo} -ge ${g_chnNums} ];then
        echo -e "\n\tERROR:${FUNCNAME}:The value of parameter 1 cannot be greater than or equal to ${g_chnNums}!\n"
        exit 1
    fi


    local locAddr; local locRole; local rmtRole; local equipId; local chName;
    local rmtAddr; local locIp;   local locPort; local rmtIp;   local rmtPort;

    local tmpStr=$(${mysqlite3} ${sqliteDbFile} "select local_addr,local_role,equipemnt_id,chn_name,rmt_addr from ${frmInfoTblName} where chn_no=${tChnNo} limit 1;")
    locAddr=$(echo "${tmpStr}"|cut -d'|' -f 1)
    locRole=$(echo "${tmpStr}"|cut -d'|' -f 2)
    equipId=$(echo "${tmpStr}"|cut -d'|' -f 3)
    chName=$(echo "${tmpStr}"|cut -d'|' -f 4)
    rmtAddr=$(echo "${tmpStr}"|cut -d'|' -f 5)

    if [ ${locRole} -eq 1 ];then
        rmtRole=2
    else
        rmtRole=1
    fi
    locIp=$(echo "${locAddr}"|cut -d':' -f 1)
    locPort=$(echo "${locAddr}"|cut -d':' -f 2)
    rmtIp=$(echo "${rmtAddr}"|cut -d':' -f 1)
    rmtPort=$(echo "${rmtAddr}"|cut -d':' -f 2)

    cp -a "${xmlModStaF}" "${tmpFile}"

    F_setXmlNodeAttrVal "${tmpFile}" "stationCfg" "stationNum" "${tChnNo}"
    F_setXmlNodeAttrVal "${tmpFile}" "localStation" "role" "${locRole}"
    F_setXmlNodeAttrVal "${tmpFile}" "localStation" "equipmentID" "${equipId}"
    F_setXmlNodeAttrVal "${tmpFile}" "localStation" "name" "${chName}"
    F_setXmlNodeAttrVal "${tmpFile}" "remoteStation" "role" "${rmtRole}"
    F_setXmlNodeAttrVal "${tmpFile}" "remoteStation" "name" "${chName}远端"

    local locLinNo=$(sed -n '/^\s*<\s*localStation\b/=' "${tmpFile}"|head -1)
    local rmtLinNo=$(sed -n '/^\s*<\s*remoteStation\b/=' "${tmpFile}"|head -1)
    locLinNo=$(echo "${locLinNo} + 1"|bc)
    rmtLinNo=$(echo "${rmtLinNo} + 1"|bc)
    F_setXmlNodeAttrVal "${tmpFile}" "netAddr" "ip" "${locIp}" "${locLinNo}"
    F_setXmlNodeAttrVal "${tmpFile}" "netAddr" "port" "${locPort}" "${locLinNo}"
    F_setXmlNodeAttrVal "${tmpFile}" "netAddr" "ip" "${rmtIp}" "${rmtLinNo}"
    F_setXmlNodeAttrVal "${tmpFile}" "netAddr" "port" "${rmtPort}" "${rmtLinNo}"

    local tTbl="${staAddPre}${tChnNo}"
    ${mysqlite3} ${sqliteDbFile} "select cfg_str from ${tTbl} order by  (addr_val+0) asc;" >"${tmpFile1}"

    sed -i 's/^/              /g' "${tmpFile1}"
    sed -i "/^\s*<\s*stationSon\s*>/ r ${tmpFile1}" "${tmpFile}"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end chnNo=[${tChnNo}]"

    return 0
}




#添加所有的站的信息
function F_addStationsCfg()
{
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."

    cat "${xmlModStasF}"|sed "s/num=\"[^\"]*\"/num=\"${g_chnNums}\"/g" >>"${dataRstCfgF}" 

    local i=0; local tRowNo=0;
    for ((i=0;i<${g_chnNums};i++))
    do
        F_addOneStationCfg "${i}"
        tRowNo=$(sed -n '/^\s*<\s*\/\s*stations\s*>/=' "${dataRstCfgF}")
        tRowNo=$(echo "${tRowNo} - 1"|bc)
        sed -i "${tRowNo} r ${tmpFile}" "${dataRstCfgF}"

        #if [ ${i} -eq 0 ];then
        #    sed -i "/^\s*<\s*stations\s/ r ${tmpFile}" "${dataRstCfgF}"
        #else
        #    tRowNo=$(sed -n '/^\s*<\s*\/\s*stations\s*>/=' "${dataRstCfgF}")
        #    tRowNo=$(echo "${tRowNo} - 1"|bc)
        #    sed -i "${tRowNo} r ${tmpFile}" "${dataRstCfgF}"
        #fi
    done

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end"

    return 0
}




#添加一个通道的会话配置到tmpFile1
function F_addOneSsnsCfg()
{
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi
    local tChnNo="$1"
    local staTbl="${staAddPre}${tChnNo}"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: in ...chnNo=[${tChnNo}]"

    cp -a "${xmlModSesF}" "${tmpFile1}"
    sed -i '/^\s*<\s*sessionInst\b/d' "${tmpFile1}" 
    local tTotal=$(${mysqlite3} ${sqliteDbFile} "select count(1) from ${staTbl} where addr_type='3';")
    local startAdd=$(${mysqlite3} ${sqliteDbFile} "select min((addr_val+0)) from ${staTbl} where addr_type='3';")
    local lastAdd=$(${mysqlite3} ${sqliteDbFile} "select max((addr_val+0)) from ${staTbl} where addr_type='3';")
    local fixNum=120
    >"${tmpFile2}" 
    local nexAddr=${startAdd}; local instNo=0; local tmpStr; local tnumber=0;
    local ttn=0;
    while [ ${nexAddr} -le ${lastAdd} ]
    do
        ttn=$(echo "${nexAddr} + ${fixNum}"|bc)
        if [ ${ttn} -gt ${lastAdd} ];then
            tnumber=$(echo "${lastAdd} - ${nexAddr} +1"|bc)
        else
            tnumber=${fixNum}
        fi
        tmpStr="<sessionInst instNo=\"${instNo}\" addrStart=\"${nexAddr}\" number=\"${tnumber}\" cmnAddr=\"1\" collMethods=\"1\" cycTm=\"\" />"
        echo "${tmpStr}">>"${tmpFile2}"

        nexAddr=$(echo "${nexAddr} + ${tnumber}"|bc)
        instNo=$(echo "${instNo} + 1"|bc)
    done
    
    sed -i 's/^/                    /g' "${tmpFile2}"
    sed -i "/^\s*<\s*sessionCfg\b/ r ${tmpFile2}" "${tmpFile1}"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end chnNo=[${tChnNo}]"

    return 0
}




#添加某个通道的所有物理量配置 到tmpFile1
function F_addChnPhyCfg()
{
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi
    local tChnNo="$1"
    local staTbl="${staAddPre}${tChnNo}"
    local addrTbl="${addrInfPre}${tChnNo}"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: in ...chnNo=[${tChnNo}]"

    >"${tmpFile1}"
    >"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,x_val_1mi from ${addrTbl} where trim(x_val_1mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,rtv_val_1mi from ${addrTbl} where trim(rtv_val_1mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,avg_val_1mi from ${addrTbl} where trim(avg_val_1mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,sdv_val_1mi from ${addrTbl} where trim(sdv_val_1mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,x_val_5mi from ${addrTbl} where trim(x_val_5mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,rtv_val_5mi from ${addrTbl} where trim(rtv_val_5mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,avg_val_5mi from ${addrTbl} where trim(avg_val_5mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,sdv_val_5mi from ${addrTbl} where trim(sdv_val_5mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,sdv_val_15mi from ${addrTbl} where trim(sdv_val_15mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,avg_val_15mi from ${addrTbl} where trim(avg_val_15mi)<>'' and is_it_used='1';" >>"${tmpFile2}"
    ${mysqlite3} ${sqliteDbFile} "select addr_val,append_add_num,x_val_15mi from ${addrTbl} where trim(x_val_15mi)<>'' and is_it_used='1';" >>"${tmpFile2}"

    local tnaa;
    local tAddVal;    local tAppNum;   local tXvalStr;
    local phy=1;      local grpNo;     local calcMethd; local hisMaxNum;
    local scalFactor; local offsetCoe; local didRowId;
    local addrNum;    local i=0;       local tmpStr;

    local ttNum=$(wc -l "${tmpFile2}"|awk '{print $1}')

    #echo ""
    while read tnaa
    do
        printf "\r%s:%s:chnNo=[${tChnNo}] do phy [%d/%d]" "$(date +%F_%T.%N)" ${FUNCNAME} ${phy} ${ttNum}
        tAddVal=$(echo "${tnaa}"|cut -d'|' -f 1)
        tAppNum=$(echo "${tnaa}"|cut -d'|' -f 2)
        tXvalStr=$(echo "${tnaa}"|cut -d'|' -f 3)
        #组号#计算方法#历史值个数#乘法系数#值偏移量#didrowid
        grpNo=$(echo "${tXvalStr}"|cut -d'#' -f 1)
        calcMethd=$(echo "${tXvalStr}"|cut -d'#' -f 2)
        hisMaxNum=$(echo "${tXvalStr}"|cut -d'#' -f 3)
        scalFactor=$(echo "${tXvalStr}"|cut -d'#' -f 4)
        offsetCoe=$(echo "${tXvalStr}"|cut -d'#' -f 5)
        didRowId=$(echo "${tXvalStr}"|cut -d'#' -f 6)

        addrNum=$(echo "${tAppNum} +1"|bc)
        cp -a "${xmlModPhyF}" "${tmpFile3}"
        sed -i '/^\s*<\s*pntAddr\b/d' "${tmpFile3}"
        sed -i '/^\s*<\s*dataId\b/d' "${tmpFile3}"

        F_setXmlNodeAttrVal "${tmpFile3}" "phyObjVal" "phyType" "${phy}"
        F_setXmlNodeAttrVal "${tmpFile3}" "phyObjVal" "grpNo" "${grpNo}"
        F_setXmlNodeAttrVal "${tmpFile3}" "phyObjVal" "calcMethd" "${calcMethd}"
        F_setXmlNodeAttrVal "${tmpFile3}" "phyObjVal" "hisMaxNum" "${hisMaxNum}"
        F_setXmlNodeAttrVal "${tmpFile3}" "phyObjVal" "scalFactor" "${scalFactor}"
        F_setXmlNodeAttrVal "${tmpFile3}" "phyObjVal" "offsetCoe" "${offsetCoe}"
        F_setXmlNodeAttrVal "${tmpFile3}" "pntAddrs" "numOfAdd" "${addrNum}"

        ${mysqlite3} ${sqliteDbFile} "select cfg_str from ${staTbl} where addr_val=${tAddVal};" >"${tmpFile4}"
        for ((i=1;i<=${tAppNum};i++))
        do
            tAddVal=$(echo "${tAddVal} +1"|bc)
            ${mysqlite3} ${sqliteDbFile} "select cfg_str from ${staTbl} where addr_val=${tAddVal};" >>"${tmpFile4}"
        done
        sed -i 's/^/                    /g' "${tmpFile4}"
        sed -i "/^\s*<\s*pntAddrs\b/ r ${tmpFile4}" "${tmpFile3}"

        ${mysqlite3} ${sqliteDbFile} "select cfg_str from ${didInfoTableName} where rowid=${didRowId};" >"${tmpFile4}"
        sed -i 's/^/                /g' "${tmpFile4}" 
        sed -i "/^\s*<\s*\/\s*pntAddrs\b/ r ${tmpFile4}" "${tmpFile3}"

        phy=$(echo "${phy} +1"|bc)

        cat "${tmpFile3}" >>"${tmpFile1}"

    done<"${tmpFile2}"

    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: end chnNo=[${tChnNo}]"

    return 0
}




#添加一个通道的配置到tmpFile
function F_addOneChnCfg()
{
    if [ $#  -ne 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameter number no eq 1 \n"
        exit 1
    fi
    local tChnNo="$1"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: in ...chnNo=[${tChnNo}]"

    local isNum=$(echo "${tChnNo}"|sed -n '/^[0-9]\+$/p'|wc -l)
    if [ ${isNum} -eq 0 ];then
        echo -e "\n\tERROR:${FUNCNAME}:parameter 1 should be a number! \n"
        exit 1
    fi

    if [ ${tChnNo} -ge ${g_chnNums} ];then
        echo -e "\n\tERROR:${FUNCNAME}:The value of parameter 1 cannot be greater than or equal to ${g_chnNums}!\n"
        exit 1
    fi


    local locAddr; local locRole; local rmtRole; local equipId; local chName;
    local rmtAddr; local locIp;   local locPort; local rmtIp;   local rmtPort;

    local tmpStr=$(${mysqlite3} ${sqliteDbFile} "select local_addr,local_role,equipemnt_id,chn_name,rmt_addr from ${frmInfoTblName} where chn_no=${tChnNo} limit 1;")
    locAddr=$(echo "${tmpStr}"|cut -d'|' -f 1)
    locRole=$(echo "${tmpStr}"|cut -d'|' -f 2)
    equipId=$(echo "${tmpStr}"|cut -d'|' -f 3)
    chName=$(echo "${tmpStr}"|cut -d'|' -f 4)
    rmtAddr=$(echo "${tmpStr}"|cut -d'|' -f 5)

    local putStagFlag=1
    if [ ${locRole} -eq 1 ];then
        rmtRole=2
    else
        rmtRole=1
        putStagFlag=2
    fi
    locIp=$(echo "${locAddr}"|cut -d':' -f 1)
    locPort=$(echo "${locAddr}"|cut -d':' -f 2)
    rmtIp=$(echo "${rmtAddr}"|cut -d':' -f 1)
    rmtPort=$(echo "${rmtAddr}"|cut -d':' -f 2)

    cp -a "${xmlModchnF}" "${tmpFile}"

    F_setXmlNodeAttrVal "${tmpFile}" "channel" "chnNum" "${tChnNo}"
    F_setXmlNodeAttrVal "${tmpFile}" "stationCfg" "stationNum" "${tChnNo}"
    F_setXmlNodeAttrVal "${tmpFile}" "localStation" "role" "${locRole}"
    F_setXmlNodeAttrVal "${tmpFile}" "localStation" "equipmentID" "${equipId}"
    F_setXmlNodeAttrVal "${tmpFile}" "localStation" "name" "${chName}"
    F_setXmlNodeAttrVal "${tmpFile}" "remoteStation" "role" "${rmtRole}"
    F_setXmlNodeAttrVal "${tmpFile}" "remoteStation" "name" "${chName}远端"

    local locLinNo=$(sed -n '/^\s*<\s*localStation\b/=' "${tmpFile}"|head -1)
    local rmtLinNo=$(sed -n '/^\s*<\s*remoteStation\b/=' "${tmpFile}"|head -1)
    locLinNo=$(echo "${locLinNo} + 1"|bc)
    rmtLinNo=$(echo "${rmtLinNo} + 1"|bc)
    F_setXmlNodeAttrVal "${tmpFile}" "netAddr" "ip" "${locIp}" "${locLinNo}"
    F_setXmlNodeAttrVal "${tmpFile}" "netAddr" "port" "${locPort}" "${locLinNo}"
    F_setXmlNodeAttrVal "${tmpFile}" "netAddr" "ip" "${rmtIp}" "${rmtLinNo}"
    F_setXmlNodeAttrVal "${tmpFile}" "netAddr" "port" "${rmtPort}" "${rmtLinNo}"
    F_setXmlNodeVal "${tmpFile}" "putStagFlag" "${putStagFlag}"

    F_addOneSsnsCfg "${tChnNo}"
    sed -i "/^\s*<\s*\/\s*stationCfg\b/ r ${tmpFile1}"  "${tmpFile}"
    F_addChnPhyCfg "${tChnNo}"
    sed -i "/^\s*<\s*\/\s*sessionCfgList\b/ r ${tmpFile1}"  "${tmpFile}"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end chnNo=[${tChnNo}]"

    return 0
}




#添加所有通道的信息
function F_addChnsCfg()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: in ..."

    cat "${xmlModChnsF}"|sed "s/num=\"[^\"]*\"/num=\"${g_chnNums}\"/g" >>"${dataRstCfgF}" 

    local i=0; local tRowNo=0;
    for ((i=0;i<${g_chnNums};i++))
    do
        F_addOneChnCfg "${i}"
        tRowNo=$(sed -n '/^\s*<\s*\/\s*channels\s*>/=' "${dataRstCfgF}")
        tRowNo=$(echo "${tRowNo} - 1"|bc)
        sed -i "${tRowNo} r ${tmpFile}" "${dataRstCfgF}"

        #if [ ${i} -eq 0 ];then
        #    sed -i "/^\s*<\s*channels\s/ r ${tmpFile}" "${dataRstCfgF}"
        #else
        #    tRowNo=$(sed -n '/^\s*<\s*\/\s*channels\s*>/=' "${dataRstCfgF}")
        #    tRowNo=$(echo "${tRowNo} - 1"|bc)
        #    sed -i "${tRowNo} r ${tmpFile}" "${dataRstCfgF}"
        #fi
    done

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: end\n"

    return 0
}




function F_genScdXml()
{
    echo -e "\n$(date +%F_%T.%N):${FUNCNAME}:INFO: -----------chnNums=[${g_chnNums}]---------in ..."
    F_addXmlHead
    F_addDidCfg
    F_addAlgCfg
    F_addStationsCfg
    F_addChnsCfg
    sed -i 's///g' "${dataRstCfgF}"
    sed -i 's/$//g' "${dataRstCfgF}"
    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: -----------chnNums=[${g_chnNums}]---------end\n"
    return 0
}




function F_cpRstFileFromData()
{
    [ ! -f "${dataRstCfgF}" ] && return 0

    local bakFile="${resultFile}.bak"

    if [ -f "${resultFile}" ];then
        mv "${resultFile}" "${bakFile}"
    fi

    iconv -f utf8 -t gbk "${dataRstCfgF}" -o "${resultFile}"

    echo -e "$(date +%F_%T.%N):${FUNCNAME}:INFO: The resulting configuration file is:[\e[1;31m${resultFile}\e[0m]\n"

    return 0
}




main()
{
    local stTmSnds=$(date +%s)

    F_init
    F_prepareData
    F_genScdXml
    F_cpRstFileFromData

    local edTmSnds=$(date +%s)
    local usedSnds=$(echo "${edTmSnds} - ${stTmSnds}"|bc)
    echo -e "\n\tTotal elapsed time[\e[1;31m${usedSnds}\e[0m] seconds\n"

    return 0
}




main

exit 0

