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
create table employee(
	name STRING,
	salary FLOAT,
	subordinates ARRAY<STRING>;
	deductions MAP<STRING,FLOAT>,
	address STRUCT<stree:STRING,city:STRING,state:STRING,zip:INT>;
)
3、hive中默认的记录和字段分隔符:
	\n 对于文本文件来说，每一行都是一条记录，因此换行符可以分割记录
	^A （'\001'） 用于分割字段
	^B （'\002'）用于分割数组中各个元素，或者键值对各个键值对
	^C （'\003'） 用于分割键值对中建和值

create table employee(
	name STRING,
	salary FLOAT,
	subordinates ARRAY<STRING>;
	deductions MAP<STRING,FLOAT>,
	address STRUCT<stree:STRING,city:STRING,state:STRING,zip:INT>;
)
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

create table if not exists mydb.employee( # 在使用其他数据库时创建mydb数据库中的employee表
	name STRING comment "name",
	salary FLOAT comment "salary",
	subordinates ARRAY<STRING> comment "sub";
	deductions MAP<STRING,FLOAT> comment "name of subordinates",
	address STRUCT<stree:STRING,city:STRING,state:STRING,zip:INT> comment "address";
)
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
create external table if not exists stocks(
	exchange string,
	sysmbol string,
	price float
)
row format delimited fields terminated by ','
location "/data/stocks"
12、describe extended tablename，可以查看表是否是管理表还是外部表

################################### 分区表
13、分区表：分层存储，比如日志
create table employee(
	name string,
	salary float
)
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

#### sql join
1、hive 只支持等值连接
2、默认的join 是内连接。内连接 inner join：只有两个表中都存在相同的数据才会保留下来
select a.ymd,a.price,b.price from stocks a join stocks b on a.ymd = b.ymd  join stocks c on a.yml = c.yml 
where a.symbol="apple" and b.symbol="ibm" and c.symbol='ge';
3、大多数情况下，hive 会对每对join连接对象启动一个mapreduce任务。在本例中，会首先启动一个mapruduce job对表a和表b进行连接操作，然后
再启动一个mapreduce任务对上一个的输出和表c进行连接操作。
4、hive总是按照从左到右的顺序执行。
5、hive同时假定查询中最后一个表示最大的表，在对每行记录进行连接操作时，他会尝试将其他的表进行缓存，然后扫描最后那个表进行计算。
因此，用户需要保证连续查询中的表的大小是按照从左到右依次增大的。
6、left outer join：保留左边表数据
7、right outer join：保留右边表数据
8、full outer join：两个表的值相同的都保留。

9、map-side join：若有搜也有表中只有一张表示小表，那么可以在最大的表通过mapper的时候将小表完全放在内存中，hive可以在map端执行
连接过程（称为map-side join）。这是因为hive和内存中小表进行逐一匹配，从而省略掉常规操作那个的reduce操作。hive的右外连接和全外连接不支持。

10、order by和sort by：
order by会对查询结果进行全局排序。会有一个所有的数据都通过reduce进行处理的操作，对于大数据集，这个过程会消耗大量的时间。hive的sort by
只会在reducer中对数据进行排序，也就是执行一个局部排序过程，这样可以保证每个reducer中的输出数据是有序的（按照sort by字段保证局部有序），
这样可以提高后面进行的全局排序的效果。

11、含有sort by的distribute by：
在使用sort by时，不同的reduce的输出内容可能会有重叠，distribute by保证相同的记录会分发到同一个reducer中进行处理，
sort by按照我们的期望进行排序。hive要求distribute by语句要写到sort by之前。
12、cluster by：如果sort by 和 distribute by 涉及的字段相同，而且是按照升序排序，则这种情况下等价于cluster by。

13、查询抽样：tablesample
create table if not exists numbers(age int);
1）使用rand()函数进行抽样： select * from numbers tablesample(bucket 3 out of 10 on rand());
2）按照指定的列抽样：select * from numbers tablesample(bucket 3 out of 10 on age);
上述分桶语句中分母表示的是数据将会被散列的桶的数量，分子是将会选择的桶的数量。

14、数据块抽样：
按照百分比进行抽样，这种是基于行数的，
select * from numbers tablesample(0.1 percent);
这种抽样的方式并不一定适用于所有的文件格式，这种抽样的最小抽样单元是一个hdfs数据块，如果一个表的数据大小小于数据块大小，将会返回所有的数据。

15、union all--将多个表进行合并，每个union 子查询必须具有相同的列。垂直方向合并


###### 第七章 HIVE 视图
1、视图可以允许保存一个查询冰箱对待表一样对这个查询进行操作。
create view short_join_view as
select * from people join cart
on cart.people_id = people.people_id 
where firstname ="join";

2、创建一个视图，取出type值为request的city，states，part三个字段，并命名为orders，视图orders具有是三个字段：states、city、part。
导入数据：
create external table dynamictable(cols map<string,string>)
row format delimited
fileds terminated by '\004'
collection iterms terminated by '\001'
map keys terminated by '\002'
stored as textfile;
  

create view orders(states,city,part) as 
select cols["states"],cols["city"],cols["part"]
from dynamictable
where cols["type"]="request";
--其中cols是dynamictable中的map字段。

3、删除视图：drop view if exists shipments;
4、视图是只读的，只允许改变与数据中tableproperties属性信息。

########## 第八章：索引
1、hive只有有限的索引功能，没有普通关系型数据库中键的概念，可以通过explain查看某个查询语句是否用到了索引。索引列不需要是唯一值。
2、
create index employee_index on table employee(country)
as 'org.apache.hadoop.hive.ql.index.compact.CompactIndexHanler'
with deferred rebuild
idxproperties("create"="me","create_at"="some time")
in table employee_index_table
partitioned by (country,name)
comment "employee indexed by country and name";

as 语句制定了索引处理器，也就是实现了索引接口的java类。可以有其他实现。
in table语句：并非一定要求索引处理器在一张新表中保留索引数据，
如果忽略partition by的话，索引将会包含原始表的所有分区。


3、bitmap索引：普遍应用于去重后值较少的列。

create index employee_index on table employee(country)
as 'bitmap'
with deferred rebuild
idxproperties("create"="me","create_at"="some time")
in table employee_index_table
partitioned by (country,name)
comment "employee indexed by country and name";


4、重建索引
如果用户指定了deferred rebuild，那么新索引将会呈现空白状态，在任何时候，都可以进行第一次索引创建或者alter index对索引进行重建。
alter index employee_index on table employee partition(country='us') rebuild;
如果省略partiton，那么将会对所有分区进行重建索引。

5、显示索引：
show formatted index on employee;

6、删除索引:
drop index if exists employee_index on table employee;

######### 第九章：模式设计
1、日志表-》按天划分-》使用分区表。
2、一个理想的分区方案不应该导致太多的分区和文件夹目录产生，并且每个目录下的文件都应该足够大，应该是文件系统中块大小的若干倍。
3、如果用户不能够找到很好的，找到大小相对合适的分区方式的话，可以考虑使用分桶表数据储存的方式。
4、同一份数据多个处理：

insert overwrite sales select * from history where action="purchase";
insert overwrite  credits select * from history from action="return";
需要扫描两次history表，效率低下
=>

from history
insert overwrite sales select * where action="purchase"
insert overwrite  credits select * from action="return";

5、分桶表：并非所有的数据都能合理的分区。
create table weblog(
	user_id int,
	url string,
	source_ip string
)
partitioned by(dt string)
clustered by (user_id) into 96 buckets;


########### 第十章：调优
1、使用explain：打印语法树。
explain select sum(number) from numbers;

2、调整限制：
在很多情况下，limit语句还是需要执行整个查询语句的，然后再返回部分结果。
hive中 hive.limit.optimize.enable = true 配置属性可以开启，当使用limit语句时，对原数据进行抽样。
这个功能有个缺点：有可能输入中有用的数据永远不会被处理到。因为抽样。

3、join优化：
1)需要清楚那个表示最大的，并将最大的表放在join的最右边，或者使用关键字指出。
2)如果所有表中有个表足够小，可以放入到内存中，那么hive可以执行map-side join，减少reduce的过程。

4、本地模式:
有时hive的输入数据量是非常小的，在这种情况下，为查询出发执行任务的时间消耗可能会比job的执行时间要多得多。
这种情况下，可以通过本地模式在单台机器上或者单个进程中处理所有的任务。
set oldjobtracker = ${hiveconf:mapred.job.tracker};
set mapred.job.tracker=local;
set mapred.tmp.dir=/homt/edward/tmp;
select * from people where firstname="bob";
set mapred.job.tracker=${oldjobtracker};

或者使用 hive.exec.mode.local.auto=true, 让hive在适当的时候启动启动这个优化。

5、并行执行：
有些job可能包含多个阶段，而这些阶段并非完全相互依赖，也就是说这些阶段是可以并行执行的，
通过设置hive.exec.parallel=true， 启动兵法执行。

6、严格模式：防止用户执行那些可能产生意向不到的不好的影响的查询。
1）对于分区表，除非where语句中含有分区字段过滤条件来限制数据范围，否则不允许执行。
	换句话说，不允许用户扫描所有的分区，浪费巨大的资源。
2）对于使用order by的查询，要求必须使用limit语句，因为order by为了排序会将所有的结果分发到同一个reducer中进行
	处理，防止消耗很长的时间。
3）限制笛卡尔积的查询。

7、调整mapper 与reducer 的个数
如果有太多的mapper或者reducer任务，就会导致启动阶段，调度和运行过程中产生过大的开销。而设置的数量太小，那么
有可能没有充分利用好集群内在的并行性。
当执行hive查询具有reduce阶段时，可以通过cli控制台的打印信息看到reducer个数。
hive按照输入的数据量大小来确定reducer 的个数，可以通过dfs -count查看输入量的大小。
hive.exec.reducers.bytes.per.reducer= reducer的平均负载，默认是1GB
hive.exec.reducers.max= reducer的最大值
mapred.reduce.tasks= recuder的数量

通过hive.exec.reducers.max 防止某些大的任务消耗太多的资源，导致其他任务不能正常执行。



