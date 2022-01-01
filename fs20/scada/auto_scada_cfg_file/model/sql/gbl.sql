PRAGMA foreign_keys=OFF;
--BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS "g_did_info" 
--全局did信息表
( 
    "did_name" NVARCHAR(128) not null,   --did名称
    "did_bin_val" NVARCHAR(128) not null, --did的二进制串
    "cfg_str"     NVARCHAR(600) DEFAULT NULL --存储scada配置中did对应的xml内容
);

CREATE TABLE IF NOT EXISTS "tmp_flag" 
--程序运行中临时flag表
( 
    "did_name_match_flag" INTEGER DEFAULT 0   --根据配置中的did名是否能查找到did: 1 能查找到;0 查找不到
);

CREATE TABLE IF NOT EXISTS "tmp_match_did" 
--程序运行中临时存储匹配的did信息
( 
    "addr_rowid" INTEGER DEFAULT 0,   --配置did名对应的addr_info_x中的rowid
    "x_val_str" TEXT(255)             --存储*_val_*mi的原串再加#和匹配的did在g_did_info中的rowid
);

--COMMIT;
