#!/bin/bash
#author:fushikai
#date: 2021-12-31_10:11:04
#DSC:生成heiyanquan测风塔和风机的did信息

sdInNum=1
if [ $# -ne ${sdInNum} ];then
    echo -e "\n\t\e[1;31mERROR\e[0m:$0 input parameters not eq \e[1;31m ${sdInNum}\e[0m !\n"
    exit 1
fi


outFile="$1"

############################## 常用修改配置区
fjBebeinNo=1 #风机开始编号
fjBeEndNo=5 #风机结束编号
fjMinTypeS=(1 5 15) #风机需要的统计分钟数类型

tCfName="测风塔1 "
#tCfName2="测风塔2 "             #此风场无测风塔2
cftHigTypeS=(10 50 80 100 110) #测风塔需要配置的高度
cftMinTypeS=(1 5 15) #测风塔需要的统计分钟数类型

cfgMulMinRsTypeS=(5) #测风塔非1分钟实时值分钟数类型

############################## 常用修改配置区


basedir="$(dirname $0)"

tCfttmp1="${basedir}/tcft$$_1.txt"
tCfttmp2="${basedir}/tcft$$_2.txt"

function F_rmExistFile() #Delete file if file exists
{
    local tInParNum=1
    local thisFName="${FUNCNAME}"
    if [ ${tInParNum} -gt  $# ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${thisFName} input parameter num less than  [${tInParNum}]!\n"
        return 1
    fi

    local tFile="$1"
    while [ $# -gt 0 ]
    do
        tFile="$1"
        if [ -e "${tFile}" ];then
            #echo "rm -rf \"${tFile}\""
            rm -rf "${tFile}"
        fi
        shift
    done
    return 0
}




trap "F_rmExistFile ${tCfttmp1} ${tCfttmp2};exit" 0 1 2 3 9 11 13 15

############################################################整场 TPS begin
#TPS理论功率 
tTpsTp1Min='
    <!--理论功率-->
    <dataId name="1分钟 整场 理论功率 平均值TPS" funcType="2" dcatalog="DATACATALOG_TP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="0" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_TPS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1" />
'
#TPS可用功率
tTpsVp1Min='
    <!--可用功率-->
    <dataId name="1分钟 整场 可用功率 平均值TPS" funcType="2" dcatalog="DATACATALOG_VP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="0" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_TPS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1" />
'
#TPS受阻功率
tTpsBp1Min='
    <!--受阻功率-->
    <dataId name="1分钟 整场 受阻功率 平均值TPS" funcType="2" dcatalog="DATACATALOG_BP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="0" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_TPS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1" />
'
#TPS实际有功
tTpsPp1Min='
    <!--实际有功-->
    <dataId name="1分钟 整场 实际有功 平均值TPS" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="0" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_TPS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1" />
'
#TPS开机容量
tTpsCp1Min='
    <!--开机容量-->
    <dataId name="1分钟 整场 开机容量 平均值TPS" funcType="2" dcatalog="DATACATALOG_CP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="0" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_TPS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1" />
'
#TPS实际风速
tTpsWs1Min='
    <!--实际风速-->
    <dataId name="1分钟 整场 实际风速 平均值TPS" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_TPS" srcsn="0" htype="HEIGHTTYPE_HUB" hvalue="65536" itype="INTERVALUNIT_MINUTE" ivalue="1" />
'
############################################################整场 TPS end



############################################################测风塔 非1分钟实时数据 begin

#0m层高非1分钟共有的实时数据
tCf0mNo1TmRsData='
    <!--0分钟 0m cft_name_place风速 实时值-->
    <dataId name="0分钟 0m cft_name_place风速 实时值" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 0m cft_name_place风向 实时值-->
    <dataId name="0分钟 0m cft_name_place风向 实时值" funcType="1" dcatalog="DATACATALOG_WD" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
'
tCf0mNo1TmRsData=$(echo "${tCf0mNo1TmRsData}"|sed "s/cft_name_place/${tCfName}/g")


#特殊层高非1分钟特有的实时数据
tCfSpmSpN1TmRsData='
    <!--0分钟 10m cft_name_place温度 实时值-->
    <dataId name="0分钟 10m cft_name_place温度 实时值" funcType="1" dcatalog="DATACATALOG_AT" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 10m cft_name_place湿度 实时值-->
    <dataId name="0分钟 10m cft_name_place湿度 实时值" funcType="1" dcatalog="DATACATALOG_AH" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 10m cft_name_place气压 实时值-->
    <dataId name="0分钟 10m cft_name_place气压 实时值" funcType="1" dcatalog="DATACATALOG_AP" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
'
tCfSpmSpN1TmRsData=$(echo "${tCfSpmSpN1TmRsData}"|sed "s/cft_name_place/${tCfName}/g")

############################################################测风塔 非1分钟实时数据 end


############################################################测风塔 所有层高共用的(风速，风向）数据 begine
#0m层高共有的1分钟数据
tCf0mData='
    <!--1分钟 0m cft_name_place风速-->
    <!--1分钟 0m cft_name_place风速 实时值-->
    <dataId name="1分钟 0m cft_name_place风速 实时值" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 0m cft_name_place风速 最大值-->
    <dataId name="1分钟 0m cft_name_place风速 最大值" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 0m cft_name_place风速 最小值-->
    <dataId name="1分钟 0m cft_name_place风速 最小值" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 0m cft_name_place风速 标准差值-->
    <dataId name="1分钟 0m cft_name_place风速 标准差值" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>

    <!--1分钟 0m cft_name_place风向-->
    <!--1分钟 0m cft_name_place风向 实时值-->
    <dataId name="1分钟 0m cft_name_place风向 实时值" funcType="1" dcatalog="DATACATALOG_WD" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 0m cft_name_place风向 最大值-->
    <dataId name="1分钟 0m cft_name_place风向 最大值" funcType="1" dcatalog="DATACATALOG_WD" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 0m cft_name_place风向 最小值-->
    <dataId name="1分钟 0m cft_name_place风向 最小值" funcType="1" dcatalog="DATACATALOG_WD" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 0m cft_name_place风向 标准差值-->
    <dataId name="1分钟 0m cft_name_place风向 标准差值" funcType="1" dcatalog="DATACATALOG_WD" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>

'
tCf0mData=$(echo "${tCf0mData}"|sed "s/cft_name_place/${tCfName}/g")

#0m层高共有的x分钟平均数据
tCf0mAvgData='
    <!--0分钟 0m cft_name_place风速 平均值-->
    <dataId name="0分钟 0m cft_name_place风速 平均值" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

    <!--0分钟 0m cft_name_place风向 平均值-->
    <dataId name="0分钟 0m cft_name_place风向 平均值" funcType="1" dcatalog="DATACATALOG_WD" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

'
tCf0mAvgData=$(echo "${tCf0mAvgData}"|sed "s/cft_name_place/${tCfName}/g")

#0m层高共有的非1分钟统计数据(除平均值之外的值)
tCf0mNo1MiSticData='
    <!--0分钟 0m cft_name_place风速 最大值-->
    <dataId name="0分钟 0m cft_name_place风速 最大值" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 0m cft_name_place风速 最小值-->
    <dataId name="0分钟 0m cft_name_place风速 最小值" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 0m cft_name_place风速 标准差值-->
    <dataId name="0分钟 0m cft_name_place风速 标准差值" funcType="1" dcatalog="DATACATALOG_WS" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

    <!--0分钟 0m cft_name_place风向 最大值-->
    <dataId name="0分钟 0m cft_name_place风向 最大值" funcType="1" dcatalog="DATACATALOG_WD" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 0m cft_name_place风向 最小值-->
    <dataId name="0分钟 0m cft_name_place风向 最小值" funcType="1" dcatalog="DATACATALOG_WD" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 0m cft_name_place风向 标准差值-->
    <dataId name="0分钟 0m cft_name_place风向 标准差值" funcType="1" dcatalog="DATACATALOG_WD" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

'
tCf0mNo1MiSticData=$(echo "${tCf0mNo1MiSticData}"|sed "s/cft_name_place/${tCfName}/g")

############################################################测风塔 所有层高共用的(风速，风向）数据 end


############################################################测风塔 没有层高的电池电压 数据begin
#电池电压x分钟值
tCfDyMinAvg='
    <!--0分钟 cft_name_place电池电压 平均值-->
    <dataId name="0分钟 cft_name_place电池电压 平均值" funcType="2" dcatalog="DATACATALOG_BL" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0" />

    <!--0分钟 cft_name_place电池电压 实时值-->
    <dataId name="0分钟 cft_name_place电池电压 实时值" funcType="2" dcatalog="DATACATALOG_BL" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0" />

    <!--0分钟 cft_name_place电池电压标准差值-->
    <dataId name="0分钟 cft_name_place电池电压标准差值" funcType="2" dcatalog="DATACATALOG_BL" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0" />

    <!--0分钟 cft_name_place电池电压 最大值-->
    <dataId name="0分钟 cft_name_place电池电压 最大值" funcType="2" dcatalog="DATACATALOG_BL" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0" />

    <!--0分钟 cft_name_place电池电压 最小值-->
    <dataId name="0分钟 cft_name_place电池电压 最小值" funcType="2" dcatalog="DATACATALOG_BL" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0" />

'
tCfDyMinAvg=$(echo "${tCfDyMinAvg}"|sed "s/cft_name_place/${tCfName}/g")

############################################################测风塔 没有层高的电池电压 数据 end

############################################################测风塔 只有10m层高特有的温湿压数据 begin
#温湿压非统计数据
tCfWSYData='
    <!--1分钟 10m cft_name_place温度-->
    <!--1分钟 10m cft_name_place温度 实时值-->
    <dataId name="1分钟 10m cft_name_place温度 实时值" funcType="1" dcatalog="DATACATALOG_AT" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 10m cft_name_place温度 最大值-->
    <dataId name="1分钟 10m cft_name_place温度 最大值" funcType="1" dcatalog="DATACATALOG_AT" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 10m cft_name_place温度 最小值-->
    <dataId name="1分钟 10m cft_name_place温度 最小值" funcType="1" dcatalog="DATACATALOG_AT" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 10m cft_name_place温度 标准差值-->
    <dataId name="1分钟 10m cft_name_place温度 标准差值" funcType="1" dcatalog="DATACATALOG_AT" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>

    <!--1分钟 10m cft_name_place湿度-->
    <!--1分钟 10m cft_name_place湿度 实时值-->
    <dataId name="1分钟 10m cft_name_place湿度 实时值" funcType="1" dcatalog="DATACATALOG_AH" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 10m cft_name_place湿度 最大值-->
    <dataId name="1分钟 10m cft_name_place湿度 最大值" funcType="1" dcatalog="DATACATALOG_AH" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 10m cft_name_place湿度 最小值-->
    <dataId name="1分钟 10m cft_name_place湿度 最小值" funcType="1" dcatalog="DATACATALOG_AH" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 10m cft_name_place湿度 标准差值-->
    <dataId name="1分钟 10m cft_name_place湿度 标准差值" funcType="1" dcatalog="DATACATALOG_AH" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>

    <!--1分钟 10m cft_name_place气压-->
    <!--1分钟 10m cft_name_place气压 实时值-->
    <dataId name="1分钟 10m cft_name_place气压 实时值" funcType="1" dcatalog="DATACATALOG_AP" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 10m cft_name_place气压 最大值-->
    <dataId name="1分钟 10m cft_name_place气压 最大值" funcType="1" dcatalog="DATACATALOG_AP" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 10m cft_name_place气压 最小值-->
    <dataId name="1分钟 10m cft_name_place气压 最小值" funcType="1" dcatalog="DATACATALOG_AP" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 10m cft_name_place气压 标准差值-->
    <dataId name="1分钟 10m cft_name_place气压 标准差值" funcType="1" dcatalog="DATACATALOG_AP" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="1"/>

'
tCfWSYData=$(echo "${tCfWSYData}"|sed "s/cft_name_place/${tCfName}/g")

#温湿压平均数据
tCfWSYAvgData='
    <!--0分钟 10m cft_name_place温度 平均值-->
    <dataId name="0分钟 10m cft_name_place温度 平均值" funcType="1" dcatalog="DATACATALOG_AT" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
        
    <!--0分钟 10m cft_name_place湿度 平均值-->
    <dataId name="0分钟 10m cft_name_place湿度 平均值" funcType="1" dcatalog="DATACATALOG_AH" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

    <!--0分钟 10m cft_name_place气压 平均值-->
    <dataId name="0分钟 10m cft_name_place气压 平均值" funcType="1" dcatalog="DATACATALOG_AP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

'
tCfWSYAvgData=$(echo "${tCfWSYAvgData}"|sed "s/cft_name_place/${tCfName}/g")

#温湿压非1分钟统计数据
tCfWSYNo1MiSticData='
    <!--0分钟 10m cft_name_place温度 最大值-->
    <dataId name="0分钟 10m cft_name_place温度 最大值" funcType="1" dcatalog="DATACATALOG_AT" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 10m cft_name_place温度 最小值-->
    <dataId name="0分钟 10m cft_name_place温度 最小值" funcType="1" dcatalog="DATACATALOG_AT" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 10m cft_name_place温度 标准差值-->
    <dataId name="0分钟 10m cft_name_place温度 标准差值" funcType="1" dcatalog="DATACATALOG_AT" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

    <!--0分钟 10m cft_name_place湿度 最大值-->
    <dataId name="0分钟 10m cft_name_place湿度 最大值" funcType="1" dcatalog="DATACATALOG_AH" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 10m cft_name_place湿度 最小值-->
    <dataId name="0分钟 10m cft_name_place湿度 最小值" funcType="1" dcatalog="DATACATALOG_AH" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 10m cft_name_place湿度 标准差值-->
    <dataId name="0分钟 10m cft_name_place湿度 标准差值" funcType="1" dcatalog="DATACATALOG_AH" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

    <!--0分钟 10m cft_name_place气压 最大值-->
    <dataId name="0分钟 10m cft_name_place气压 最大值" funcType="1" dcatalog="DATACATALOG_AP" dkind="DATAKIND_MAX" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 10m cft_name_place气压 最小值-->
    <dataId name="0分钟 10m cft_name_place气压 最小值" funcType="1" dcatalog="DATACATALOG_AP" dkind="DATAKIND_MIN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 10m cft_name_place气压 标准差值-->
    <dataId name="0分钟 10m cft_name_place气压 标准差值" funcType="1" dcatalog="DATACATALOG_AP" dkind="DATAKIND_SDV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AMT" ecsn="0" srctype="SOURCETYPE_AMT" srcsn="0" htype="HEIGHTTYPE_ES" hvalue="10" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

'
tCfWSYNo1MiSticData=$(echo "${tCfWSYNo1MiSticData}"|sed "s/cft_name_place/${tCfName}/g")

############################################################测风塔 只有10m层高特有的温湿压数据 end



############################################################风机数据  begin

#    <!--1分钟 风机0 计算发电量-->
#    <dataId name="1分钟 风机0 计算发电量" funcType="2" dcatalog="DATACATALOG_GE" dkind="DATAKIND_CLV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
#    <!--1分钟 风机0 理论功率 实时值-->
#    <dataId name="1分钟 风机0 理论功率 实时值" funcType="2" dcatalog="DATACATALOG_TP" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
#    <!--1分钟 风机0 风机状态int-->
#    <dataId name="1分钟 风机0 风机状态int" funcType="2" dcatalog="DATACATALOG_SF" dkind="DATAKIND_OGN" dtype="DATATYPE_SINT32" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
#    <!--1分钟 风机0 A相电压-->
#    <dataId name="1分钟 风机0 A相电压" funcType="2" dcatalog="DATACATALOG_PV" dkind="DATAKIND_PSA" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
#    <!--1分钟 风机0 A相电流-->
#    <dataId name="1分钟 风机0 A相电流" funcType="2" dcatalog="DATACATALOG_PI" dkind="DATAKIND_PSA" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
#    <!--1分钟 风机0 功率因数 实时值-->
#    <dataId name="1分钟 风机0 功率因数 实时值" funcType="2" dcatalog="DATACATALOG_PF" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>

#heiyanquan单风机的did
tjxycFjSingle='
    <!--1分钟 风机0 风机状态float-->
    <dataId name="1分钟 风机0 风机状态float" funcType="2" dcatalog="DATACATALOG_SF" dkind="DATAKIND_OGN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 风机0 有功功率 实时值-->
	<dataId name="1分钟 风机0 有功功率 实时值" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!-- 1分钟 风机0 无功功率 实时值-->
	<dataId name="1分钟 风机0 无功功率 实时值" funcType="2" dcatalog="DATACATALOG_PQ" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 风机0 风速 实时值-->
	<dataId name="1分钟 风机0 风速 实时值" funcType="2" dcatalog="DATACATALOG_WS" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 风机0 风向 实时值-->
	<dataId name="1分钟 风机0 风向 实时值" funcType="2" dcatalog="DATACATALOG_WD" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 风机0 桨距角 实时值-->
    <dataId name="1分钟 风机0 桨距角 实时值" funcType="2" dcatalog="DATACATALOG_PA" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 风机0 发电机转速 实时值-->
    <dataId name="1分钟 风机0 发电机转速 实时值" funcType="2" dcatalog="DATACATALOG_RS" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 风机0 环境温度 实时值-->
    <dataId name="1分钟 风机0 环境温度 实时值" funcType="2" dcatalog="DATACATALOG_AT" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <!--1分钟 风机0 累积发电量-->
    <dataId name="1分钟 风机0 累积发电量" funcType="2" dcatalog="DATACATALOG_GE" dkind="DATAKIND_AMV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>

'

#    <!--0分钟 风机0 桨距角 平均值-->  <!--注意此量没有平均值-->
#    <!--0分钟 风机0 环境温度 平均值--><!--注意此量只有1分钟表有值，所以只能所瞬时值代替平均值-->
#   <!--0分钟 风机0  发电机转速 平均值--><!--注意此量没有平均值-->
#    <!--0分钟 风机0 累积发电量 平均值--><!--注意此量没有平均值,虽然5分和15分表里有值-->
#    <dataId name="0分钟 风机0 累积发电量 平均值" funcType="2" dcatalog="DATACATALOG_GE" dkind="DATAKIND_AMV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
#    <!--0分钟 风机0 理论功率 平均值-->
#    <dataId name="0分钟 风机0 理论功率 平均值" funcType="2" dcatalog="DATACATALOG_TP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

#heiyanquan单风机 平均值
tjxycFjSingleAVG='
    <!--0分钟 数据-->
    <!--0分钟 风机0 有功功率 平均值-->
    <dataId name="0分钟 风机0 有功功率 平均值" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 风机0 无功功率 平均值-->
    <dataId name="0分钟 风机0 无功功率 平均值" funcType="2" dcatalog="DATACATALOG_PQ" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 风机0 风速 平均值-->
	<dataId name="0分钟 风机0 风速 平均值" funcType="2" dcatalog="DATACATALOG_WS" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>
    <!--0分钟 风机0 风向 平均值-->
	<dataId name="0分钟 风机0 风向 平均值" funcType="2" dcatalog="DATACATALOG_WD" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_TURBINE" ecsn="0" srctype="SOURCETYPE_TSS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="0"/>

'
############################################################风机数据  end



##heiyanquan超短期预测数据did  暂时不用
#tjxycUPSAbout='
#    <dataId name="超短期预测数据" funcType="1" dcatalog="DATACATALOG_PP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_MODEL" ecsn="65536" srctype="SOURCETYPE_UTF" srcsn="65536"  itype="INTERVALUNIT_MINUTE" ivalue="15"/>
#
#'


#############################################################整场 IAS 和 AGC begin
#heiyanquan整场相关数据did
tjxycFarmAbout='
    <dataId name="1分钟 整场 有功功率 实时值IAS" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="1分钟 整场 无功功率 实时值IAS" funcType="2" dcatalog="DATACATALOG_PQ" dkind="DATAKIND_RTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="1分钟 整场 有功功率 平均值IAS" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="1分钟 整场 无功功率 平均值IAS" funcType="2" dcatalog="DATACATALOG_PQ" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="5分钟 整场 有功功率 平均值IAS" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="5"/>
    <dataId name="5分钟 整场 无功功率 平均值IAS" funcType="2" dcatalog="DATACATALOG_PQ" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="5"/>
    <dataId name="15分钟 整场 有功功率 平均值IAS" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="15"/>
    <dataId name="15分钟 整场 无功功率 平均值IAS" funcType="2" dcatalog="DATACATALOG_PQ" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="15"/>
    <dataId name="整场累计发电量IAS" funcType="2" dcatalog="DATACATALOG_GE" dkind="DATAKIND_AMV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="整场开机台数IAS" funcType="2" dcatalog="DATACATALOG_TA" dkind="DATAKIND_PGG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="整场开机容量IAS" funcType="2" dcatalog="DATACATALOG_CP" dkind="DATAKIND_PGG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="整场待风台数IAS" funcType="2" dcatalog="DATACATALOG_TA" dkind="DATAKIND_WWG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="整场待风容量IAS" funcType="2" dcatalog="DATACATALOG_CP" dkind="DATAKIND_WWG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="整场检修台数IAS" funcType="2" dcatalog="DATACATALOG_TA" dkind="DATAKIND_SPG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="整场检修容量IAS" funcType="2" dcatalog="DATACATALOG_CP" dkind="DATAKIND_SPG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="整场限功率台数IAS" funcType="2" dcatalog="DATACATALOG_TA" dkind="DATAKIND_PGGTHV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="整场限功率容量IAS" funcType="2" dcatalog="DATACATALOG_CP" dkind="DATAKIND_PGGTHV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="通信中断台数" funcType="2" dcatalog="DATACATALOG_TA" dkind="DATAKIND_CBG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="通信中断容量IAS" funcType="2" dcatalog="DATACATALOG_CP" dkind="DATAKIND_CBG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_FARM" ecsn="0" srctype="SOURCETYPE_IAS" srcsn="0" itype="INTERVALUNIT_MINUTE" ivalue="1"/>
    <dataId name="整场数据时间AGC" funcType="2" dcatalog="DATACATALOG_DS" dkind="DATAKIND_LMT" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AGC" ecsn="0" srctype="SOURCETYPE_AGC" srcsn="0" itype="INTERVALUNIT_INVALID" ivalue="0"/>
    <dataId name="1分钟 AGC整场有功功率 平均值AGC" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_TLN" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AGC" ecsn="0" srctype="SOURCETYPE_AGC" srcsn="0" itype="INTERVALUNIT_INVALID" ivalue="1"/>
    <dataId name="限电目标值AGC" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_LMT" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AGC" ecsn="0" srctype="SOURCETYPE_AGC" srcsn="0" itype="INTERVALUNIT_INVALID" ivalue="1"/>
    <dataId name="有功上限值AGC" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_UTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AGC" ecsn="0" srctype="SOURCETYPE_AGC" srcsn="0" itype="INTERVALUNIT_INVALID" ivalue="1"/>
    <dataId name="有功下限值AGC" funcType="2" dcatalog="DATACATALOG_PP" dkind="DATAKIND_LTV" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AGC" ecsn="0" srctype="SOURCETYPE_AGC" srcsn="0" itype="INTERVALUNIT_INVALID" ivalue="1"/>
    <dataId name="理论功率AGC" funcType="2" dcatalog="DATACATALOG_TP" dkind="DATAKIND_AVG" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AGC" ecsn="0" srctype="SOURCETYPE_AGC" srcsn="0" itype="INTERVALUNIT_INVALID" ivalue="1"/>
    <dataId name="限电标志AGC" funcType="2" dcatalog="DATACATALOG_SF" dkind="DATAKIND_LMT" dtype="DATATYPE_FLOAT64" dlen="" amount="1" ectype="ENCODETYPE_AGC" ecsn="0" srctype="SOURCETYPE_AGC" srcsn="0" itype="INTERVALUNIT_INVALID" ivalue="1"/>

'
#############################################################整场 IAS 和 AGC begin

#echo "${tjxycFjSingle}"

#测风塔把0m数据变成x米数据的函数
function F_jxycCftToXmCom()
{

    local sdInNum=2
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi
    local toNO="$1"
    local writeFile="$2"

    echo "${tCf0mData}"|sed -e "s/\b0m\b/${toNO}m/g" -e "s/hvalue=\"0\"/hvalue=\"${toNO}\"/g" >>${writeFile}

    return 0
}

#测风塔生成直采的数据DID
function F_jxycCftGenDirDid()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    [ ! -z "${tCfWSYData}" ] && echo "${tCfWSYData}" >> ${writeFile}

    local thgVal
    for thgVal in ${cftHigTypeS[*]}
    do
        F_jxycCftToXmCom "${thgVal}" ${writeFile} 
    done

    #echo "${tCf0mData}"|sed -e "s/\b0m\b/${toNO}m/g" -e "s/hvalue=\"0\"/hvalue=\"${toNO}\"/g" >>${writeFile}

    return 0
}

#测风塔生成x分钟的统计did
function F_jxycCftToXMin()
{

    local sdInNum=2
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi
    #local toNO="$1"
    local toMinu="$1"
    local writeFile="$2"

    local thgVal

    [ ! -z "${tCfDyMinAvg}" ] && echo "${tCfDyMinAvg}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}


    if [ "${toMinu}" == "1" ];then
        for thgVal in ${cftHigTypeS[*]}
        do
            echo "${tCf0mAvgData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g"  -e "s/\b0m\b/${thgVal}m/g" -e "s/hvalue=\"0\"/hvalue=\"${thgVal}\"/g">>${writeFile}
            if [ ${thgVal} -eq 10 ];then
                echo "${tCfWSYAvgData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}
            fi
        done

    else
        for thgVal in ${cftHigTypeS[*]}
        do
            echo "${tCf0mAvgData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g"  -e "s/\b0m\b/${thgVal}m/g" -e "s/hvalue=\"0\"/hvalue=\"${thgVal}\"/g">>${writeFile}
            echo "${tCf0mNo1MiSticData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g"  -e "s/\b0m\b/${thgVal}m/g" -e "s/hvalue=\"0\"/hvalue=\"${thgVal}\"/g">>${writeFile}
            
            if [ ${thgVal} -eq 10 ];then
                echo "${tCfWSYAvgData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}
                echo "${tCfWSYNo1MiSticData}"|sed -e "s/0分钟/${toMinu}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}
            fi
        done
    fi


    return 0
}

#测风塔生成1 5 15 分钟的统计 数据DID
function F_jxycCftGenStaticDid()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"
    local tMinTy

    for tMinTy in ${cftMinTypeS[*]}
    do
        F_jxycCftToXMin "${tMinTy}" "${writeFile}"
    done

    return 0
}


function F_jxycFjToX()
{

    local sdInNum=2
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi
    local toNO="$1"

    if [ ${toNO} -lt 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} fei ji no less than 1  toNO=[${toNO}]!\n"
        exit 1
    fi

    local toCodeNo=$(echo "${toNO} - 1"|bc)

    local writeFile="$2"

    echo "${tjxycFjSingle}"|sed -e "s/风机0/风机${toNO}/g" -e "s/ecsn=\"0\"/ecsn=\"${toCodeNo}\"/g" >>${writeFile}


    return 0
}


function F_jxycFjToXAVG()
{

    local sdInNum=3
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi
    local toNO="$1"

    if [ ${toNO} -lt 1 ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} fei ji no less than 1  toNO=[${toNO}]!\n"
        exit 1
    fi

    local toCodeNo=$(echo "${toNO} - 1"|bc)

    local writeFile="$2"
    local toMinu="$3"

    echo "${tjxycFjSingleAVG}"|sed -e "s/风机0/风机${toNO}/g" -e "s/0分钟/${toMinu}分钟/g" -e "s/ecsn=\"0\"/ecsn=\"${toCodeNo}\"/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" >>${writeFile}
    #echo "${tjxycFjSingleAVG}"|sed -e "s/风机0/风机${toNO}/g" -e "s/0分钟/${toMinu}分钟/g" -e "s/ecsn=\"0\"/ecsn=\"${toNO}\"/g" -e "s/ivalue=\"0\"/ivalue=\"${toMinu}\"/g" 


    return 0
}

#heiyanquan其他数据DID
function F_jxycOtherDid()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    [ ! -z "${tjxycUPSAbout}" ] && echo "${tjxycUPSAbout}" >> ${writeFile}
    [ ! -z "${tjxycFarmAbout}" ] && echo "${tjxycFarmAbout}" >> ${writeFile}


    return 0
}


#heiyanquan tps数据DID
function F_jxycTpsDid()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    [ ! -z "${tTpsTp1Min}" ] && echo "${tTpsTp1Min}" >> ${writeFile}
    [ ! -z "${tTpsVp1Min}" ] && echo "${tTpsVp1Min}" >> ${writeFile}
    [ ! -z "${tTpsBp1Min}" ] && echo "${tTpsBp1Min}" >> ${writeFile}
    [ ! -z "${tTpsPp1Min}" ] && echo "${tTpsPp1Min}" >> ${writeFile}
    [ ! -z "${tTpsCp1Min}" ] && echo "${tTpsCp1Min}" >> ${writeFile}
    [ ! -z "${tTpsWs1Min}" ] && echo "${tTpsWs1Min}" >> ${writeFile}


    return 0
}

#heiyanquan数据DID文件头
function F_jxycDidFileHead()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    local tHead='<?xml version="1.0" encoding="gb2312" standalone="no" ?>
<root idNum="1383">

'
    echo "${tHead}" >> ${writeFile}

    return 0
}

#heiyanquan数据DID文件尾
function F_jxycDidFileTail()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    local tTail='
</root>

'
    echo "${tTail}" >> ${writeFile}

    return 0
}



#heiyanquan 生成测风塔的did数据
function F_jxycDidGenCftAll()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"

    >"${tCfttmp1}"
    
    #生成 测风塔 的数据
    F_jxycCftGenDirDid "${tCfttmp1}"
    F_jxycCftGenStaticDid "${tCfttmp1}"
    cat "${tCfttmp1}" >>${writeFile}

    #生成 测风塔2 的数据
    if [ ! -z "${tCfName2}" ];then
        cp "${tCfttmp1}" "${tCfttmp2}"
        sed -i -e "s/${tCfName}/${tCfName2}/g" -e "s/ecsn=\"0\"/ecsn=\"1\"/g" "${tCfttmp2}"
        cat "${tCfttmp2}" >>${writeFile}
    fi


    return 0
}


#heiyanquan 生成测风塔的非1分钟实时值did数据
function F_jxycDidGenOthRsCftAll()
{

    if [ -z "${tCf0mNo1TmRsData}" ];then
        return 0
    fi

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"
    
    >"${tCfttmp1}"

    local tm
    local ht

    #生成 测风塔 的数据
    for tm in ${cfgMulMinRsTypeS[*]}
    do
        for ht in ${cftHigTypeS[*]}
        do
            echo "${tCf0mNo1TmRsData}"|sed -e "s/0分钟/${tm}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${tm}\"/g"  -e "s/\b0m\b/${ht}m/g" -e "s/hvalue=\"0\"/hvalue=\"${ht}\"/g">>${tCfttmp1}
        done
    done

    #特殊层高的
    for tm in ${cfgMulMinRsTypeS[*]}
    do
        echo "${tCfSpmSpN1TmRsData}"|sed -e "s/0分钟/${tm}分钟/g" -e "s/ivalue=\"0\"/ivalue=\"${tm}\"/g"  >>${tCfttmp1}
    done

    cat "${tCfttmp1}" >>${writeFile} 

    #生成 测风塔2 的数据
    if [ ! -z "${tCfName2}" ];then
        cp "${tCfttmp1}" "${tCfttmp2}"
        sed -i -e "s/${tCfName}/${tCfName2}/g" -e "s/ecsn=\"0\"/ecsn=\"1\"/g" "${tCfttmp2}"
        cat "${tCfttmp2}" >>${writeFile}
    fi



    return 0
}



#heiyanquan 生成风机的did数据
function F_jxycDidGenFjAll()
{

    local sdInNum=1
    if [ $# -ne ${sdInNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR:\e[0m functon ${FUNCNAME} input parameter not eq  [${sdInNum}]!\n"
        exit 1
    fi

    #local toNO="$1"
    local writeFile="$1"
    
    local t
    local tMinTye
    
    #瞬时值
    for ((t=${fjBebeinNo};t<=${fjBeEndNo};t++))
    do
        F_jxycFjToX "$t" "${writeFile}"
    done

    #各分钟的数据
    for tMinTye in ${fjMinTypeS[*]}
    do
        #${tMinTye}分钟
        for ((t=${fjBebeinNo};t<=${fjBeEndNo};t++))
        do
            #echo " $t ${writeFile} ${tMinTye}"
            F_jxycFjToXAVG "$t" "${writeFile}" "${tMinTye}"
        done
    done

    return 0
}


#F_jxycFjToXAVG 2 "xx" 5
#exit 0

#F_jxycFjToX 70 3
#exit 0

>${outFile}

#heiyanquan数据DID文件头
F_jxycDidFileHead "${outFile}"

#heiyanquan 生成测风塔的did数据
F_jxycDidGenCftAll "${outFile}"

#heiyanquan 生成风机的did数据
F_jxycDidGenFjAll "${outFile}"

#heiyanquan其他数据DID
F_jxycOtherDid "${outFile}"

#heiyanquan tps数据DID
F_jxycTpsDid "${outFile}"

#heiyanquan 非1分钟实时值数据DID
F_jxycDidGenOthRsCftAll "${outFile}"

#heiyanquan数据DID文件尾
F_jxycDidFileTail "${outFile}" 



function F_prtfindKeyVal()
{
    local inNum=2
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    
    local tKey="$1"
    local tmpStr="$2"
    
    #echo -e "${tmpStr}"|awk -F'[= "]'  '{for(i=1;i<=NF;i++){if($i ~/'${tKey}'/ ){print $(i+2);break;} }}'
    #tDidName=$(sed -n "${tDidLinNo} p" ${tcfgFile}|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/(name|didName)/){print $(i+1);break;}}}')
    #echo -e "${tmpStr}"|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/\<'${tKey}'\>/){print $(i+1);break;}}}'
    echo -e "${tmpStr}"|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/ +'${tKey}'\s*=/){print $(i+1);break;}}}'

    return 0
}


function F_setFixLinKeyVal()
{
    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi
    
    local tLine="$1"
    local tKey="$2"
    local tVal="$3"
    local tEdFile="$4"
    if [ $# -gt 4 ];then
        local proCont="$5"
    fi

    if [ ! -e "${tEdFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in function ${thisFName} edit file [${tEdFile}] not exist!\n"
        return 2
    fi

    local tmpStr=$(sed -n "${tLine} {p;q}" ${tEdFile})
    local tOldVal=$(F_prtfindKeyVal "${tKey}" "${tmpStr}")

    if [ "${tOldVal}" == "${tVal}" ];then
        #echo "[${tOldVal}] eq [${tVal}]"
        return 0
    fi

    #tmpStr=$(echo "${tmpStr}"|sed -e 's///g' -e 's/^\s\+//g')
    #echo -e "line[${LINENO}]:file:[${tEdFile}] \e[1;31m${proCont}\e[0m line:[${tLine}] content:[${tmpStr}] ,modify [\e[1;31m${tKey}\e[0m]'s value [\e[1;31m${tOldVal}\e[0m] to [\e[1;31m${tVal}\e[0m]  "

    sed -i "${tLine} s/\b${tKey}\b\s*=\s*\"[^\"]*\"/${tKey}=\"${tVal}\"/g" ${tEdFile}
    

    return 0
}

tLinNum=$(sed -n '/^\s*<\s*\bdataId\b/p' ${outFile}|wc -l)
tBgTm=$(date +%s)
echo -e "\n\t====================remove spaces in didName in file [${outFile}]=============================begin"
i=0
j=0
k=0
t=0
loopTm[0]=${tBgTm}
loopTm[1]=${tBgTm}
sed -n '/^\s*<\s*dataId\b/=' ${outFile}|while read tnaa
do
    let i++
    #if [ $(echo "$i % 100"|bc) -eq 0 ];then
    #    k=$(echo "$j % 2"|bc)
    #    let j++
    #    t=$(echo "$j % 2"|bc)
    #    loopTm[${t}]=$(date +%s)
    #    tLpDfTm=$(echo "${loopTm[${t}]} - ${loopTm[${k}]}"|bc)
    #    echo "----do lines:[${i}/${tLinNum}]---elapsed[${tLpDfTm}]seconds"
    #fi
    printf "\r----do lines:[%d/%d]" ${i} ${tLinNum}
    tmpStrstr=$(sed -n "${tnaa} {p;q}" ${outFile})
    didName=$(F_prtfindKeyVal "name" "${tmpStrstr}")
    didName=$(echo "${didName}"|sed 's/\s\+//g')
    F_setFixLinKeyVal "${tnaa}" "name" "${didName}" "${outFile}" "delete name s blank char"
done
    echo -e "\n----do lines:[${tLinNum}]---"
    tEdTm=$(date +%s)
    tRTm=$(echo "${tEdTm} - ${tBgTm}"|bc) 
    echo -e "\n\tremove spaces elapsed time [\e[1;31m${tRTm}\e[0m] seconds"
echo -e "\t====================remove spaces in didName in file [${outFile}]=============================end\n"


#tLinNum=$(sed -n '/^\s*<\s*\bdataId\b/p' ${outFile}|wc -l)
#echo "----tLinNum=${tLinNum}----"

sed -i "/^\s*<\s*root\b/{s/idNum\s*=\s*\"[^\"]*\"/idNum=\"${tLinNum}\"/g}" "${outFile}" 

exit 0

