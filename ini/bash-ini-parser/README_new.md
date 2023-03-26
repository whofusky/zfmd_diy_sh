# 各版本简短说明


`更新时间: 2023-03-24_13:07:31 `

</br>

> 文档中术语说明:    
>> section : 指代ini配置的域名即[ ]符号括起来的部分    
>> key : 指代ini配置的配置的=号前的变量名    
>> idx : 指处理某一个ini文件对应的索引号(索引号为数字,针对同一个ini文件对应
索引号相同,引入索引号是为了同时处理多个ini文件区别不同文件)    

</br>

------------------------------------------------------------------------------

+ Table of Contents     
     - [各版本简短说明](#各版本简短说明)      
     - [主要文件说明](#主要文件说明)        
     - [建议](#建议)        
     - [sed版详细说明](#sed版详细说明)       
        - [支持的ini格式说明](#支持的ini格式说明)       
        - [工具解析ini的原理](#工具解析ini的原理)       
        - [工具在脚本中的使用方法](#工具在脚本中的使用方法)      
            - [工具涉及的方法如下:](#工具涉及的方法如下)     
            - [使用举例](#使用举例)        
        - [附](#附)      
            - [脚本中对格式处理的代码](#脚本中对格式处理的代码)      

------------------------------------------------------------------------------

</br>

### 主要文件说明 


```
.
├── bash-ini-parser.asItIs  
├── bash-ini-parser.bash
├── bash-ini-parser.sed

```

bash-ini-parser.asItIs 较原始版本的 ini file parser for bash relying only on builtins   

bash-ini-parser.bash A ini file parser for bash relying only on builtins   

bash-ini-parser.sed 在原始版的基础之上用sed命令解析ini文件(比bash-ini-parser.bash版本快很多)

### 建议

    bash-ini-parser.sed文件在没有发现明确问题之前，推荐此文件对ini文件进行解析与处理，原因如下:

1. 解析ini文件效率高(速度快)
2. 支持的格式完善
3. 可以在同一个脚本中针对多个ini文件同时解析

</br>


------------------------------------------------------------------------------

</br>


## sed版详细说明

### 支持的ini格式说明

1. 不同系统间的兼容性    
    目前测试支持 linux 和 windows 两大类格式的ini配置文件

2. 整体格式说明      
    section(域名)和key(键)一般要求是脚本可识别的变量名(不要有汉字)    

3. 注释符号说明     
    (1) 支持两种符号的注释`;`和`#`  
    (2) 注释的位置可以是行注释,也可以是行尾注释,但
推荐行注释,因为行尾注释有不完善之处;如果使用行尾注释须遵循如下规则:    
    (2.1) 注释符前有多个空格    
    (2.2) 注释内容中不能有双引号和单引号  

    举例如下:    

```
;这是行注释
#这是行注释

key=val1    ;这是行尾注释
key1=val2   #这是行尾注释
```

4. section说明      
    (1) 不推荐ini中没有section的key值,如果有则工具自动给没有section的key添加AUTOADD_ROOT为section值 
    (2) `[` 或 `]`左右的空格工具会自动去掉      
    (3) 名中间最好不能有空格，如果有空格则工具会把多个连续的空格转换成`_`符号   

    举例如下:   

```

#存在没有域名的键值
key=val1
则工具转换后为
[AUTOADD_ROOT]
key=val1

[ section 1  2  ]
则工具会自动转换成
[section_1_2]
```

4. key值的说明      
    (1) `=`号左右可以有空格,但工具会自动去掉=左右空格       
    (2) =号后的值最后可以有空格,工具会自动去掉(但值中间的空格不会去掉)      
    (3) 值可以用单引号或双引号引起来,没有加引号的,工具自动添加双引号        
    (4) key对应的值不能跨行(即使加引号也不行)   

    举例如下:   

```
key =  value 1    #有空格,无引号
#则工具自动转换成
key="value 1"

product_name=  fusk \"=\" pv f20   #注释
#则工具自动转换成
product_name="fusk \"=\" pv f20"

#正确
key=val1-1 val1-2 val1-3 ... val1-n
#错误
key="val1-1
val1-2 val1-3 ...
val1-n"

```

</br>

  [返回顶部](#各版本简短说明)      

------------------------------------------------------------------------------

</br>


### 工具解析ini的原理

bash_ini-parser.sed 支持在同一个程序中对多个不同的ini文件进行解析;脚本解析ini的原理
为将ini文件中section解析成bash 函数，section下的key值解析成函数下的变量；变量名就是
ini配置文件的key；    

工具解析多个ini文件内容不冲突的实现机制为根据不同ini文件的**索引号(从0开始)**
把sedion转换成函数时添加了不同的函数头，索引号、函数头及调试相关的全局变量如下      

```shell

# 索引号
#  1. 索引号需要是一个数字
#  2. 同一个ini文件所用的方法对应的索引号需要相同

# 不同的索引号对应section固定前缀为:
#  cfg_${idx}_section_ 

# 不同的索引号对应调试变量:
#   g_bash_ini_${idx}[x]  此变量一个数组变量，存的值为ini解析后的shell函数
#   注：要打印以上变量还需要export BASH_INI_PARSER_DEBUG=1   



```


**举例**    

ini文件内容如下:    

```

;正式的授权文件，文件名为: "电场ID.aits"

prod_desc="test"

;产品组成描述
[PROD_COMPO DESC]

;版权信息
copyright="兆方美迪风能工程(上海)有限公司"

;产品名
product_name=  fusk \"=\" pv f20   #注释


;产品版本号
;product_ver='V20.000.001'    ;又一种注释
    product_ver='^PASS_MAX_DAYS'  ;又一种注释
    fuskytest="#"    

;一级ID层级信息
[ID]

;场站主ID
main_id=gaolongshan
;电场名称
main_name=高龙山风电场

```

假定解析时输入的索引号为0则解析之后的脚本内容为:    

```shell
cfg_0_section_AUTOADD_ROOT () {
F_ini_inner_unset 0 ${FUNCNAME/#cfg_0_section_}
prod_desc="test"
}
cfg_0_section_PROD_COMPO_DESC () {
F_ini_inner_unset 0 ${FUNCNAME/#cfg_0_section_}
copyright="兆方美迪风能工程(上海)有限公司"
product_name="fusk \"=\" pv f20"
product_ver='^PASS_MAX_DAYS'
fuskytest="#"
}
cfg_0_section_ID () {
F_ini_inner_unset 0 ${FUNCNAME/#cfg_0_section_}
main_id="gaolongshan"
main_name="高龙山风电场"
}
```

</br>


  [返回顶部](#各版本简短说明)      

------------------------------------------------------------------------------

</br>

### 工具在脚本中的使用方法



#### 工具涉及的方法如下:      

```
#Determine whether the index is a number
#return state: 1 wrong; 0 right
F_right_index <idx>           

#Output the contents of g_bash_ini_${idx}
F_ini_debug <idx> [arg]       

#解析ini文件成shell函数并应用到当前环境中
F_ini_cfg_parser <idx> <ini_file> 

#按ini格式缓存中的idx对应的文件内容
F_ini_cfg_writer <idx> [section] 

#内部使用,没有做过多检验,外部使用请用F_ini_cfg_unset
F_ini_inner_unset <idx> [section]

#unset 环境变量
F_ini_cfg_unset <idx> [section]  

#unset function
F_ini_cfg_clear <idx> [section]  

#添加或更新缓存中的ini值
F_ini_cfg_update <idx> <section> <key> 

#判断是否有section: 0 有, 其他值没有
F_ini_is_section <idx> <section> 

#按ini的当前section(函数生效):0 成功,其他值表示没有此section
F_ini_enable_section <idx> <section> 

#判断是否有key: 0 有, 其他值没有
#注意此函数调的前提是已经调用了F_ini_enable_section才有效
#    因此key是针对某个section来说的，脱离section谈key是不成立的
F_ini_is_key <key>              

#判断是否有section或key: 0 有, 其他值没有
F_ini_is_cfg ${index} <section> [key]

```

</br>

#### 使用举例

ini文件部分内容:

```
;产品组成描述
[PROD_COMPO DESC]

;版权信息
copyright="兆方美迪风能工程(上海)有限公司"

#产品名
product_name=  fusk \"=\" pv f20   #注释
```
1. 定义索引号，相同ini文件的方法需要使用同样的索引号(目录只支持0或1如下要扩展需要工具脚本进行少量修改)      

```shell
    #定义使用两套ini文件的索引
    iniIdex=0
```

2. 定义工具路径,ini路径,引用及解析ini   

```shell
    #ini解析工具定义
    parseToolFile="${baseDir}/../bash-ini-parser.sed"
    TEST_FILE="${1:-aits.ini}"

    #引用工具以便使用工具中的方法
    source ${parseToolFile}

    #parsing ini file
    F_ini_cfg_parser "${iniIdex}" "$TEST_FILE"
```

3. 对解析后的值进行处理

```shell
    
    local section="PROD_COMPO_DESC" #域名
    local key="copyright"           #键名

    #让当前域名生效,以便使用该域下的key配置
    F_ini_enable_section "${iniIdex}" "${section}" ; ret=$?
    if [ ${ret} -ne 0 ];then
        echo "ERROR:没有此域名"
        return 1
    fi

    #判断是否有相应键值
    F_ini_is_key "${key}"; ret=$?
    [ ${ret} -ne 0 ] && return ${ret}

    #输出取到的键值:ini中的key就是当前shell环境中的变量名
    echo "[${section}] -> ${key}=${!key}"
    echo "copyright=[${copyright}]"

    #更改key值
    product_name="wpfs20111"
    #将key值更新到g_bash_ini_x中去
    F_ini_cfg_update "${iniIdex}" "${section}" "product_name"

    #添加一个原来ini不存在的key
    fusky=test
    F_ini_cfg_update "${iniIdex}" "${section}" "fusky"

    #将缓存中g_bash_ini_x的值用ini的格式打印输出
    F_ini_cfg_writer "${iniIdex}"

```

</br>



  [返回顶部](#各版本简短说明)      

------------------------------------------------------------------------------

</br>


### 附 

#### 脚本中对格式处理的代码

```shell

    # read the file and 
    # 1. remove linefeed i.e dos2unix 
    # 2. 去掉;或#的行注释  去掉;或#的行尾注释
    # 3. 去掉空行
    # 4. 去掉行首和行尾的空格
    #           s/\r$//g;
    #           s/^\s*[;#]\+.*//g; s/\s\+[;#]\+[^"'\'']*$//g;
    #           /^\s*$/d;
    #           s/^\s\+//g; s/\s\+$//g;
    tmp_ini="$(sed 's/\r$//g;s/^\s*[;#]\+.*//g; 
s/\s\+[;#]\+[^"'\'']*$//g;/^\s*$/d;s/^\s\+//g; s/\s\+$//g' "$1")"

    #如果ini配置文件存在没有section的key(没有时只能发生在文件开头)时则自动
    #添加AUTOADD_ROOT的section
    local tnum="$(echo "${tmp_ini}"|sed -n '1{/^\[/p;q}'|wc -l)"
    if [ ${tnum} -eq 0 ];then
        tmp_ini="[AUTOADD_ROOT]
${tmp_ini}"
    fi

    #
    # 第一个sed:
    # 1.将域名的[或]左右空格去掉; [转换成\[ 将域名的]转换成\]; 将域名的空格转换成_
    # 2. 去掉=号左右的空格
    # 3. 等号右边没有引号的加引号
    # 4. 将\[变成}\n${PREFIX_x} 
    #    将\]变成 () {\n F_ini_inner_unset ${idx} {FUNCNAME/#cfg_x_section_}
    # 5  在末尾加上}
    # 
    # 第二个sed:
    # 1 去掉第一行的}
    #
 $(echo "${tmp_ini[*]}"|sed ' 

/^\s*\[/{s+^\s*\[\s*+\\[+g; s+\s*\]\s*$+\\]+g;s/\s\+/_/g}; 

s/\s*=\s*/=/g;

/^[^\\]/{s/=\([^"'\'']\)\(.*\)/="\1\2"/g;s/\\\[/\[/g;s/\\\]/\]/g};

/^\\\[/{s/^\\\[/\}\n'${tPreFix}'/g;s/\\\]/ \(\) \{\nF_ini_inner_unset '${idx}' 
\$\{FUNCNAME\/#'${tPreFix}'\}/g  };

$ a\}

  '|sed '1d') 

```

</br>


  [返回顶部](#各版本简短说明)      

------------------------------------------------------------------------------

</br>

