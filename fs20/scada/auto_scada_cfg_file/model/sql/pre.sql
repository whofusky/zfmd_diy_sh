PRAGMA foreign_keys=OFF;
--BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS "frm_info" 
--风场信息表包括通道数量,风场名等信息
( 
    "frm_name"      NVARCHAR(200) , --风场名
    "data_local_ip" NVARCHAR(128) , --与数据中心通信scada端ip
    "data_rmt_ip"   NVARCHAR(128) , --数据中心通信ip
    "chn_no"        INTEGER       , --通道编号:从0开始且须连续
    "equipemnt_id"  INTEGER       , --设备编号:用于scada告警用
    "local_addr"    NVARCHAR(128) , --当前通道scada端ip:端口
    "local_role"    INTEGER       , --当前通道scada角色:1 主动站; 2 被动站
    "chn_name"      NVARCHAR(128) , --通道名称
    "rmt_addr"      NVARCHAR(128)   --当前通道对端ip:端口
);

--COMMIT;
