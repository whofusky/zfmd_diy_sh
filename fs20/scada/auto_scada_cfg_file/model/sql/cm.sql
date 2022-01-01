

select * from g_did_info where did_name like '%温度%';

select '15分钟'||did_core_name0||did_core_name1||did_core_name2 from addr_info_0 where x_val_15mi<>'';

select count(1) from g_did_info where did_name in(select '15分钟'||did_core_name0||did_core_name1||did_core_name2 from addr_info_0 where x_val_15mi<>'');
select * from g_did_info where did_name in(select '15分钟'||did_core_name0||did_core_name1||did_core_name2 from addr_info_0 where x_val_15mi<>'');

select a.x_val_1mi||'#'||b.rowid from addr_info_0 a,g_did_info b where trim(a.x_val_1mi)<>'' and b.did_name='1分钟'||a.did_core_name0||a.did_core_name1||a.did_core_name2;
select a.x_val_1mi||'#'||b.rowid from addr_info_0 a,g_did_info b where trim(a.x_val_1mi)<>'' and b.did_name='1分钟'||a.did_core_name0||a.did_core_name1||a.did_core_name2;


insert into tmp_match_did select a.rowid,a.x_val_1mi||'#'||b.rowid from addr_info_0 a,g_did_info b where trim(a.x_val_1mi)<>'' and b.did_name='1分钟'||a.did_core_name0||a.did_core_name1||a.did_core_name2;

update addr_info_0 set x_val_1mi=(select x_val_str from tmp_match_did where addr_rowid=addr_info_0.rowid) where EXISTS (select x_val_str from tmp_match_did where addr_rowid=addr_info_0.rowid);


select '<dataId didVal="'||did_bin_val||'" serialNo="'||rowid||'" didName="'||did_name||'"/>' from g_did_info;
update g_did_info  set  cfg_str='<dataId didVal="'||did_bin_val||'" serialNo="'||rowid||'" didName="'||did_name||'"/>';

select '<pntAddr remoteAddr="'||addr_val||'" localAddr="'||(addr_val+(offset_to_local))||'" name="'||addr_name||'" type="'||addr_type||'" startBit="0" bitLength="16" codCoefficient="1" pntDataLng="16" offset="0" unitDesc="" encoding="0"/>' from addr_info_0;

select '<pntAddr remoteAddr="'||(addr_val+1)||'" localAddr="'||(addr_val+1+(offset_to_local))||'" name="'||addr_name||'" type="'||addr_type||'" startBit="0" bitLength="16" codCoefficient="1" pntDataLng="16" offset="0" unitDesc="" encoding="0"/>' from addr_info_0;


select rowid,append_add_num from addr_info_0 where append_add_num>0 order by (addr_val+0) asc;
