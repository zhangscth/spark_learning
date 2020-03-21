## 一：hive
1、hive 不是完整的数据库，不支持记录级别的更新，插入或者删除，但是用户可以通过生成新表或者将查询结果导入到文件中。
2、hive不支持事务。
3、MapReduce：
	map->sort->shuffle->reduce
	在mapreduce计算框架中，某个键的所有键值对会被分发到同一个reduce操作中。
4、Metastore（元数据存储）是一个独立的关系型数据库（通常是一个MySql实例，hive中默认是Derby），hive会在其中保存表模式和其他系统元数据。
5、hive -e "select * from mytable limit3" # 在命令行中执行，执行完退出hive
6、hive -f "/path/query.hql" #从文件中执行hiveQL脚本
7、在hive CLI中执行hql文件 hive> source /path/query.hql
8、在hive CLI中执行shell 命令： hive> ! pwd；# 已感叹号！开头，分号；结尾
9、在hive CLI中使用-- 注释

## 二：数据类型和文件格式
1、hive中没有键的概念，但是可以对表建立索引
2、hive 实例：
create table employee{
	name STRING,
	salary FLOAT,
	subordinates ARRAY<STRING>;
	deductions MAP<STRING,FLOAT>,
	address STRUCT<stree:STRING,city:STRING,state:STRING,zip:INT>;
}
3、hive中默认的记录和字段分隔符:
	\n 对于文本文件来说，每一行都是一条记录，因此换行符可以分割记录
	^A （'\001'） 用于分割字段
	^B （'\002'）用于分割数组中各个元素，或者键值对各个键值对
	^C （'\003'） 用于分割键值对中建和值

create table employee{
	name STRING,
	salary FLOAT,
	subordinates ARRAY<STRING>;
	deductions MAP<STRING,FLOAT>,
	address STRUCT<stree:STRING,city:STRING,state:STRING,zip:INT>;
}
ROW FORMAT DELIMITED
FILEDS TERMINATED BY '\001'
COLLECTIONS ITEMS TERMINATED BY '\002'
MAP KEYS TERMINATED BY '003'
LINES TERMINATED BY '\n'
STORED AS TEXTFILE;

4、传统数据库是写时模式，即数据在写入数据库是对模式（结构）进行检查，hive不会在数据加载时进行验证，而是在查询时进行，也就是读时模式

## 三 数据定义
1、创建数据库： create  database if not exist financials;
2、当我们创建数据库时，hive会在/usr/hive/warehouse/（hive.metastore.warehouse.dir中定义）中创建finaicials.db，也可以通过如下方式修改默认的位置：
	create database financials location '/mypath/'
3、使用数据库： use financials；
4、删除数据库: drop database if exist financials；
5、创建表完整：

create table if not exists mydb.employee{ # 在使用其他数据库时创建mydb数据库中的employee表
	name STRING comment "name",
	salary FLOAT comment "salary",
	subordinates ARRAY<STRING> comment "sub";
	deductions MAP<STRING,FLOAT> comment "name of subordinates",
	address STRUCT<stree:STRING,city:STRING,state:STRING,zip:INT> comment "address";
}
comment "description of the table"
ROW FORMAT DELIMITED
FILEDS TERMINATED BY '\001'
COLLECTIONS ITEMS TERMINATED BY '\002'
MAP KEYS TERMINATED BY '003'
LINES TERMINATED BY '\n'
STORED AS TEXTFILE;

6、默认情况下，hive总将创建的表的目录放在该表所在的数据库文件中，不过default数据库是个例外，他没有数据库目录，
它直接放在/usr/hive/warehouse/（hive.metastore.warehouse.dir中定义）。除非用户指定路径
7、复制表的模式: create table if not exists mydb.employee2 like mydb.employee;
8、查看数据库中的所有的表: show tables;
9、查看表的结构： describe financials；
10、hive中默认创建的表又称之为“内部表”/“管理表”

################################外部表
11、外部表：删除外部表并不会删除原来的数据，只会删除表的元数据。
create external table if not exists stocks{
	exchange string,
	sysmbol string,
	price float
}
row format delimited fields terminated by ','
location "/data/stocks"
12、describe extended tablename，可以查看表是否是管理表还是外部表

################################### 分区表
13、分区表：分层存储，比如日志
create table employee{
	name string,
	salary float
}
partitioned by(country string, state string)
数据的存储格式:../employee/country=CA/state=AB

14、事实上，除非需要优化查询性能，否则使用这些表的用户不需要关心字段是否是分区字段，对数据分区，也许最重要的是为了更快的查询。
select * from employee where country="us" and state="AB";

15、show partitions employee; #查看表中存在的所有分区
16、删除表：drop table if exists employee;
17、修改表：alter table log_message ...
18、表重命名：alter table log_message rename to LogMsg;


### 第五章：数据操作
1、向管理表中装载数据：
load data local inpath '${env:home}/california-employee'
overwrite into table employee
partition(country="us",state="CL")
# local :本地数据，否则是hdfs数据
2、如果目标表是分区表，那么需要使用partition子句，而且必须为每个分区的键指定一个值。
3、通过查询语句向表中插入数据：
insert overrwrite table employees partitions(country=="us", state="OR") select * from staged_employee se where se.country="us" and se.st="OR";
4、静态分区插入：
from staged_employee se
insert overwrite table employee
	partition(country="us",state="OR")
	select * select se.country="us" and se.st="OR"
insert overwrite table employee
	partition(country="us",state="AB")
	select * select se.country="us" and se.st="AB"
insert overwrite table employee
	partition(country="us",state="CD")
	select * select se.country="us" and se.st="CD"
insert overwrite table employee
	partition(country="us",state="EF")
	select * select se.country="us" and se.st="EF";

5、动态分区插入：可以基于查询参数推断出需要创建的分区名称
insert overwrite table employee
partition(country,state)
select ...,se.cnty,se.st
from staged_employee se;
hive 会自动根据最后两列来确定分区字段county和state的值，hive是根据位置关系而不是命名来匹配的。
6、也可以混合使用动态和静态分区，下面的例子，county是静态分区，指定的值为us，state为动态值
insert overwrite table employee
partition(country="us",state)
select ...,se.cnty,se.st
from staged_employee where se.cnty="US"

7、创建表并加载数据：
create table ca_employee 
as select * from employee
wheree state="ca"

8、导出数据
1)使用hadoop fs -cp source_path target_path
2) insert overwrite local directory "/tmp/mypath"
select name,salary,address from employee;


########## 第六章 hiveQL 查询
1、查询数组中的值： select name,suborinates[0] from employee;
2、查询map中的值： select name,deductions["state taxes"] from employee;
3、查询struct中的值：select name,address.city from employee;
4、使用正则表达式：select symbol,'price.*' from stocks;
5、聚合函数：select count(*),avg(salary) from employee;
6、表生成函数：select explode(subordinates) as sub from employee;
7、条件语句：
select name,salary,
case 
	when salary<5000 then 'low'
	when salary>=5000 and salary<7000 then 'mid'
	else 'high'
end as bracket
from employee;

9、本地模式：hive 什么情况下可以避免进行mapreduce
1）select * from employee; # 简单读取存储目录下的文件
2）过滤条件只有分区字段
select * from employee where country="us" and state="ca" limit 100;
3) 如果 hive.exec.mode.local.auto的值设置成true的话，hive会尝试使用本地模式执行其他的操作。否则hive使用mapreduce进行其他的查询

10、不能再where语句中使用列别名。
11、group by、 having

