

intRDD = sc.parallelize([1,2,3,4])
init.collect()

#transform

def addOne(x):
	return x+1
	
intRDD.map(addOne)
intRDD.map(x=>x+1)

intRDD.filter(x=>x>3).collect()
intRDD.distinct().collect()
sRDD = intRDD.randomSplit([0,4,0.6])
sRDD[0].collect()


intRDD1 = sc.parallelize([1,2,3])
intRDD2 = sc.parallelize([3,4,5])

intRDD1.union(intRDD2).collect()
intRDD1.intersection(intRDD2)
intRDD1.substract(intRDD2)
intRDD1.cartesian(intRDD2)


# action
intRDD.first()
intRDD.take(2)
intRDD.takeOrdered(3) // 从小到大排序，取前三个
intRDD.takeOrdered(3,key=lambda x:-x)// 从大到小排序，取前三个
intRDD.stats() //统计，count，max，min，mean，stdev
intRDD.min()
intRDD.max()
intRDD.mean()
intRDD.sum()
intRDD.stdev()

#key value
kvRDD = sc.parallelize((1,2),(3,4),(5,6),(3,5))
kvRDD.keys()
kvRDD.values().collect()
kvRDD.filter(x=>x[0]<5).collect() //找到key小于5的键值对
kvRDD.filter(x=>x[1]<5).collect() //找到value小于5的键值对

kvRDD.mapValue(lambda x:x*x).collect() // 每个value变成原来的平方
kvRDD.sortByKey(ascending=True).collect() // key从小到大排序
kvRDD.sortByKey(ascending=False).collect() // key从大到小排序
kvRDD.reduceByKey(lambda x,y:x+y).collect() // 相同key的值进行累加



kvRDD2 = sc.parallelize([3,8])

kvRDD.join(kvRDD2) // 按keyjoin ((3,(4,8)),(3,5,8))
kvRDD.leftOuterJoin(kvRDD2) // 按keyjoin ((1,(2,None)),(3,(4,8)),(5,(6,None)),(3,5,8))
kvRDD.substractByKey(kvRDD2) // 删除相同key的键值对
kvRDD.countByKey()// 计算每个key出现的次数

kvRDD.collectAsMap()// 创建kv字典，字典中key唯一

kvRDD.lookup(3) // [4,5] value为4和5

# 共享变量

## broadcast 广播
广播变量不能被修改
sc.broadcast([1,2,3,4])


## accumulator累加器
intRDD = sc.parallelize([1,2,3,4])
total = sc.accumulator(0.0) // 初始化为0.0 double
num = sc.accumulator(0)
intRDD.foreach(lambda x:[total.add(x),num.add(1)]) // total= total+x, num = num+1
avg = total.value/ num.value


# persistence 持久化
将重复运算的RDD 存储到内存中，已加快运算
intRDD.persist(...) // MEMORY_ONLY MEMORY_AND_DISK MEMORY_AND_SER MEMORY_AND_DISK_SER DISK_ONLY
intRDD.is_cached // 查看是否缓存
intRDD.unpersist() // 取消持久化


###### wordcount
textfile = sc.textFile("test.txt")
stringRDD = textfile.flatMap(lambda x:x.split(" "))
countTextRDD = stringRDD.map(lambda x:(x,1)).reduceByKey(lambda x,y:x+y)
countTextRDD.saveAsTextFile("output.txt")


from pyspark import SparkContext
from pyspark import SparkConf

def createSparkConf():
	sparkConf = SparkConf().setAppName("wordcount")
	sc = SparkContext(conf=sparkConf)
	print(sc.master)
	return(sc)
	
	
spark-submit --driver-memory 2g --master local[4] wordcount.py


#去除第一行
header = text.first() #text.take(1) feature name
rawdata = text.filter(lambda x:x!=header)
#处理分类特征 one-hot encoding
categeries = ling.map(lambda feature:feature[3]).distinct().zipWithIndex().collectAsMap()
print(len(categeries)) // 查看项数
categeriesFeature = np.zeros(len(categeries))
categeriesFeature[categeriesIndex] = 1

#处理缺失值 “？”  
def convert_float(x):
	return 0 if x=="?" else float(x)
	
def extract_label(field):
	return int(field[-1])
	

	
from pyspark.mllib.regression import LabeledPoint
labeldPointRDD = lines.map(lambda line:LabeledPoint(extract_label(line),extract_feature(line[3:])))

trainData,validateData,testData =  labeldPointRDD.randomSplit([8,1,1])
print("train data:",trainData.count())
 

#为了加快程序的运行，将数据保存在内存中

trainData.persist()
validateData.persist()
testData.persist()

# 决策树训练模型
from pyspark.mllib.tree import DecisionTree

model = DecisionTree.trainClassfier(trainData,numClasses=2,categericalFeatureInfo={},Impurity="entropy",maxDepth=5,maxBins=5)

descDict = {0:"positive",1:"negetive"}

for data in testData:
	predictResult = model.predict(data[1])
	print("predict label",descDict[predictResult])
	

#评估模型
def auc(data):
	from pyspark.mllib.evaluation import BinaryClassificationMetrics
	predict = model.predict(data.map(lambda x:x.feature))
	scoreAndLabel = predict.zip(data.map(lambda x:x.label))
	metrics = BinaryClassificationMetrics(scoreAndLabel)
	return metrics.areaUderROC
	
#查看decision tree的结构
model.toDebugString()

# 逻辑回归
from pyspark.mllib.classification import LogisticRegressionWithSGD
from pyspark.mllib.feature import StandardScaler

###标准化

stdscaler = StandardScaler(withMean=True,withStd=True).fit(featureRDD)
scaledFeature = stdscaler.transform(featureRDD)
labelPoint = labelRDD.zip(scaledFeature)
labelPointRDD = labelPoint.map(lambda x:LabeledPoint(x[0],x[1]))

#model
model = LogisticRegressionWithSGD.train(labelPointRDD,num_iter,learning_rate,batch_size)
	

	
# svm
from pyspark.mllib.classification import SVMWithSGD

model = SVMWithSGD(trainData,num_iter,learning_rate,regParam)

#naiveBayes
from pyspark.mllib.classification import NaiveBayes
model = NaiveBayes.train(trainData,lambdaParam)





#DataFrame

sqlContext = SparkSession.builder.getOrCreate()
from pyspark.sql import Row
userRDD = rawUserRDD.map(x=>x.split("|"))
user_row = userRDD.map(lambda p:Row(userid=int(p[0]),age=int(p[1]),gender=p[2])) # schema
user_row.take(5)

user_df = sqlContext.createDataFrame(user_row)
user_df.printSchema()



#SparkSQL
user_df.registerTempTable("user_table")
sqlContext.sql("select count(*) from user_table").show()

# RDD DataFrame SQL 对比

1、选择
#### RDD 只能通过索引获取值
userRDD = rawUserRDD.map(x=>x.split("|"))
userRDDNew = userRDD.map(x=>(x[0],x[1],x[2]))
### DataFrame 能通过列名获取，（通过定义schema），可以通过select选择相应的列
user_df.select(["user_id","age"]).show()
### sql 通过sql语句获取

2、增加字段
#RDD:
user_rdd_new = userRDD.map(x=>(x[0],x[1],2020-x[2]))
#dataframe
user_df.select("userid","gender",(2020-user_df["age"]).alias("birthyear")).show()
#sql
sqlContext.sql("select userid,age,2020-age as birthyear from user_table").show()

3、筛选数据
#rdd
userRDDNew.map(x=>x[0]=="zhangsan" and x[1]=="male").take(5)
#dataframe
user_df.filter("name=='zhangsan'").filter("age==10").show(5)
#sql
sqlContext.sql("selecet * from user_table where age==10").show()

4、排序
#RDD
userRDDNew.takeOrdered(5,lambda x:int(x[1])) # 按年龄排序
userRDDNew.takeOrdered(5,lambda x:-1*int(x[1])) # 按年龄降序
userRDDNew.takeOrdered(5,lambda x:(-1*int(x[1],x[2])) # 按年龄降序,按x【2】升序
#DataFrame
user_df.select("user_id","age","occupation").orderBy("age",ascending=0).show()
user_df.select("user_id","age","occupation").orderBy(["age","gender"],ascending=[0,1]).show()
#sql
sqlContext.sql("select * from user_table order by age desc").show()

5、去重
#RDD
userRDD.distinct().take(5)
#DataFrame
user_df.select("age","age").distinct().show()
#Sql
sqlContext.sql("select distinct age,gender from user_table").show()

6、分组
map reduceByKey
groupby
group by

7、join

user_df.join(zip_code_df,on="zip_code",how="left")
user_df.join(zip_code_df,user_df.zipcode==zip_code_df.zipcode,how="left")
sqlContext.sql("select * from a left join b on a.age = b.age")



#pandas

import pandas

user_pandas_df = user_df.toPandas().set_index("name")
