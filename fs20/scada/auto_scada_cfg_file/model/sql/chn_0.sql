
CREATE TABLE IF NOT EXISTS "station_addr_0" 
--站_0的点表信息
( 
    "addr_val" TEXT(20),   --点地址值
    "addr_type" TEXT(5),   --点地址类型 1 遥信; 3 遥测
    "addr_name" TEXT(255),  --点地址名
    "cfg_str"   NVARCHAR(800)  --存储scada配置中点对应的xml内容
);

CREATE TABLE IF NOT EXISTS "addr_info_0" 
--点表_0信息
( 
    "addr_val" TEXT(20),   --点地址值
    "addr_name" TEXT(255),  --点地址名
    "did_core_name0" TEXT(255), --did域名0
    "did_core_name1" TEXT(255), --did域名1
    "did_core_name2" TEXT(255), --did域名2
    "did_suffix_name" TEXT(255), --did域名:此名放在did拼接的名最后
    "append_add_num" TEXT(20), --在当前地址值基础上还需要往下递增的点地址数
    "offset_to_local" TEXT(20),--对应scada中localAddr值需要在addr_val上的偏移量
    "is_it_used" TEXT(5),     --此点地址是否用在物理量中0:不用 1用
    "addr_type" TEXT(5),      --点地址类型 1 遥信; 3 遥测
    "x_val_1mi" TEXT(255),      --1分钟值但此域在查did名时不用额外加名直接加实时,平均等字样,格式为:组号#计算方法#历史值个数#乘法系数#值偏移量
    "rtv_val_1mi" TEXT(255),    --1分钟实时值,格式同x_val_1mi
    "avg_val_1mi" TEXT(255),    --1分钟平均值格式同x_val_1mi
    "sdv_val_1mi" TEXT(255),    --1分钟标准差,注意此处若填写一般是批从瞬时值得到的值格式同x_val_1mi
    "x_val_5mi" TEXT(255),      --5分钟值但此域在查did名时不用额外加名直接加实时,平均等字样,格式同x_val_1mi
    "rtv_val_5mi" TEXT(255),    --5分钟实时值格式同x_val_1mi
    "avg_val_5mi" TEXT(255),    --5分钟平均值格式同x_val_1mi
    "sdv_val_5mi" TEXT(255),    --5分钟标准差,注意此处若填写一般是批从瞬时值得到的值格式同x_val_1mi
    "sdv_val_15mi" TEXT(255),   --15分钟标准差,注意此处若填写一般是批从瞬时值得到的值格式同x_val_1mi
    "avg_val_15mi" TEXT(255),   --15分钟平均值格式同x_val_1mi
    "x_val_15mi" TEXT(255)      --15分钟值但此域在查did名时不用额外加名直接加实时,平均等字样,格式同x_val_1mi
);

