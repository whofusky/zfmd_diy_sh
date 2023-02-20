
# 光伏2.0防火墙脚本

> 此脚本及脚本同级包含的所有文件和目录都需要一起使用，不能分开;     
>
> 此脚本及脚本需配合配置界面配置防火墙规则生成界面格式的配置文件传与此脚本使用;    
>
> 此防火墙的实现用的是iptables    
>    
> 此防火墙采用的的"白名单"机制: 即 只有配置了规则的才放行,没有配置的默认都不放行
>

## 脚本提供的功能及调用参数

```
    please input like:
        ./opfw   0   <infile> #应用界面防火墙规则
        ./opfw   1            #永久打开防火墙
        ./opfw   2            #永久停用防火墙
        ./opfw   3            #临时开启防火墙
        ./opfw   4            #临时停用防火墙
        ./opfw   5            #查看生效的防火墙规则
```

说明:
> 1. `./opfw` 只是调用脚本的一种方式，只要能访问到opfw即可   
>    
> 2. <infile>  此参数是界面配置好规则时生成的文件
>    



## 主要文件或目录说明:

```
./
├── basesh/                 #基础操作脚本
├── cfg/                    #脚本自己的配置文件目录
│   ├── network.conf            #脚本自己的正在生效的配置文件
│   ├── network.conf.0          #脚本自己配置文件的备份(10个文件滚动备份)
│   ├── network.conf.1
│   ├── network.conf.2
│   ├── network.conf.3
│   ├── network.conf.4
│   ├── network.conf.5
│   ├── network.conf.6
│   ├── network.conf.7
│   ├── network.conf.8
│   └── network.conf.9
├── log/                    #脚本自己的日志目录
│   ├── opfw.log                #opfw操作时产生的日志文件(此文件有最大限制,超过则脚本对历史内容删除处理)
│   └── systemdOpIptables.log   #systemd类型的系统systemctl操作时产生的日志文件
├── opfw                    #主操作脚本
├── opfw_ver.ini            #版本文件
├── README.md               #说明文件
└── tmp                     #临时目录
    └── pv_fw_item_config.ini   #备份的界面生成的输入文件
```






