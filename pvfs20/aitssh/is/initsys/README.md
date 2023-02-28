
# 操作系统基本环境配置

> 执行此操作之前需要在服务器上先安装linux操作系统

> 一 操作系统安全补丁
>    不放在此部分操作，补丁需要安装完操作系统后，手动安装，不放在产品级操作中去;

## 风电2.0初始脚本功能梳理

### RHEL6.7

1. 限制root用户才能执行
2. 给执行脚本赋予执行权限
3. 部署磁盘统计脚本duFs20SpaceUsage.sh到 /root/bin/
4. 给 /etc/r.local 及 /etc/rc.d/rc.local赋予执行权限
5. 修改/etc/profile文件添加默认环境变量
6. 修改/etc/sysctl.conf文件
7. 执行addSecurity.sh脚本
> 1. /etc/pam.d/system-auth 添加 password requisite
> 2. /etc/login.defs
>> PASS_MAX_DAYS 90
>> PASS_MIN_DAYS 0
>> PASS_MIN_LEN 8
>> PASS_WARN_AGE 10
> 3. /etc/pam.d/ssh 添加 auth reuuired
> 4. /etc/pam.d/login 添加 auth reuuired
> 5. /etc/pam.d/remote 添加 auth reuuired

8. 执行addUser.sh脚本
   zfmd audit security  gzz
9. 执行fs20mkdir.sh脚本
10. 执行closeservice.sh脚本
11. 执行fcust.sh脚本 给.bashrc和.vimrc添加变量和快捷键
12. 执行setAutoDesk.sh" 编辑/etc/gdm/custom.conf文件添加自动登录用户
13. 气象服务器执行setNtpMete.sh脚本编辑/etc/ntp.conf文件添加ntp校时
14. 重启服务器

### UniKylin3.3

1. 限制root用户才能执行
2. 给执行脚本赋予执行权限
3. 部署磁盘统计脚本duFs20SpaceUsage.sh到 /root/bin/
4. 给 /etc/r.local 及 /etc/rc.d/rc.local赋予执行权限
5. 停firewalld防火墙并关闭他的开机自启动
6. 修改/etc/profile文件添加默认环境变量
7. 修改/etc/sysctl.conf文件
8. 执行addUser.sh脚本
   zfmd  gzz
9. 执行fs20mkdir.sh脚本
10. 执行fcust.sh脚本 给.bashrc和.vimrc添加变量和快捷键
11. 执行setAutoDesk.sh" 编辑/etc/lightdm/lightdm.conf文件添加自动登录用户
12. 气象服务器执行setNtpMete.sh脚本编辑/etc/ntp.conf文件添加ntp校时
13. 重启服务器


## 光伏2.0功能

1. 涉及用户及密码的安防设置(包括密码复杂度、密码用效期、登录失败限制等)
2. 操作系统用户创建
3. 关闭不必要的系统服务
4. 设置系统环境变量
  > (1) /etc/prifle设置
  > (2) 主要用户下.bash_profile设置
  > (3) /etc/rc.local设置
5. 设置内网固定ip地址

5. 基础脚本部署(如果有)
6. 设置开机自动登录桌面系统
7. 根据不同服务器设置
  > (1) 气象服务器打开ntp校时服务

