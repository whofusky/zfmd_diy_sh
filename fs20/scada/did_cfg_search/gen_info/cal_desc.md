| prtl_no | calc_methd | his_max_num | in_or_out |          cal_name          |                  note                   |
|---------|------------|-------------|-----------|----------------------------|-----------------------------------------|
| 106     | 165        | 0           | 1         | 将遥信量拼成int值入库               | 一般用于风机状态的拼接中                            |
| 106     | 167        | 0           | 1         | 取直采float值                  | modbus-tcp采集两个存储器存一个float值              |
| 106     | 169        | 0           | 1         | 直采float求标量平均值              | 一般对应167方法的标量求平均                         |
| 106     | 168        | 2           | 1         | 直采float求风向平均值              | 一般对应167方法的风向求平均                         |
| 106     | 170        | 2           | 1         | 直采float求标量标准差              | 一般对应167方法的标量求标准差                        |
| 106     | 171        | 2           | 1         | 直采float求风向标准差              | 一般对应167方法的风向求标准差                        |
| 106     | 181        | 0           | 1         | 取直采inverse_float值          | modbus-tcp采集两个存储器存一个float值              |
| 106     | 180        | 0           | 1         | 直采inverse_float求标量平均值      | 一般对应181方法的标量求平均                         |
| 106     | 177        | 2           | 1         | 直采inverse_float求风向平均值      | 一般对应181方法的风向求平均                         |
| 106     | 178        | 2           | 1         | 直采inverse_float求标量标准差      | 一般对应181方法的标量求标准差                        |
| 106     | 179        | 2           | 1         | 直采inverse_float求风向标准差      | 一般对应181方法的风向求标准差                        |
| 106     | 186        | 0           | 1         | 取直采int32值                  | modbus-tcp采集两个存储器存一个int32值              |
| 106     | 172        | 0           | 1         | 取DATAFORMAT_DATE7B1类型的本地时间 | 将时间存入dtValue_p->phyObjVal_p(不常用,只在庄河用过) |
| 106     | 183        | 0           | 1         | 废弃用法                       | 考虑用167替换                                |
| 106     | 185        | 0           | 1         | 废弃用法                       | 考虑用181替换                                |
| 106     | 162        | 0           | 1         | 废弃用法                       | 考虑用167替换                                |
| 106     | 164        | 0           | 1         | 废弃用法                       | 考虑用169替换                                |
| 106     | 175        | 0           | 1         | 废弃用法                       | 考虑用181替换                                |
| 106     | 176        | 0           | 1         | 废弃用法                       | 考虑用180替换                                |
| 104     | 182        | 0           | 1         | 庄河AGC限电标志推测                | 此算法临时用,如果要通用考虑通过calPhyValByAlgPhy中实现    |
| 104     | 161        | 0           | 1         | 直接保存                       | 用于104接收实时数据                             |
| 104     | 163        | 0           | 1         | 标量求平均                      | 对应162的标量求平均值                            |
| 104     | 189        | 2           | 1         | 风向求平均                      | 对应162的风向求平均值                            |
| 104     | 166        | 0           | 1         | 值改变才保存                     | 属于废弃算法现已不用，只用于过庄河                       |
| 104     | 161        | 0           | 2         | 直接取数给点地址                   | 用于104协议出库                               |
| 106     | 162        | 0           | 2         | 将值拆分成2个点对应的值               | 一般用于modbus出库                            |
| 106     | 172        | 0           | 2         | 获取time加8小时值拆分到2个点地址中去      | 考虑废弃不用,目前只有庄河在用                         |
| 104     | 173        | 20          | 2         | 超短期数据出库                    | 特定的超短出库且phyValLng须为128                  |
| 104     | 187        | 0           | 1         | 求目标算法物理量(多个)的和(每次求和覆盖之前的值） | 即每次把目标物理量当时的值相加给当前物理量                   |
| 104     | 188        | 0           | 1         | 求目标算法物理量平均值                | 累加求和,入库的时候再求平均                          |
| 106     | 187        | 0           | 1         | 求目标算法物理量(多个)的和(每次求和覆盖之前的值） | 即每次把目标物理量当时的值相加给当前物理量                   |
| 106     | 188        | 0           | 1         | 求目标算法物理量平均值                | 累加求和,入库的时候再求平均                          |