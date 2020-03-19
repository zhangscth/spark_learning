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
1、创建数据库： create  database if not exists financials;
2、当我们创建数据库时，hive会在/usr/hive/warehouse/（hive.metastore.warehouse.dir中定义）中创建finaicials.db，也可以通过如下方式修改默认的位置：
	create database financials location '/mypath/'
3、使用数据库： use financials；
4、删除数据库: drop database if exists financials；
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
10、hive中默认创建的表又称之为“内部表”
