TDH-Docker
==========


  A collection of docker containers for supporting TDH.


# Hadoop Metrics
A document on available metrics for the Hadoop ecosystem and methods to perform time-series analysis on them.

​
## HDFS
HDFS filesystem analysis can be performed through the extraction of fsimage files
from the  NameNode server via rest API call. The fsimage file is
run through an offline image viewer which can convert block info to csv format
for import into RDBMS, I used MySQL.

* FSImage Retrieval
```
curl -X GET "http://$namenode:50070/imagetransfer?getimage=1&txid=latest" --output $outfile
```

* FSImage conversion to CSV
```
hdfs oiv  -p Delimited -delimiter "," -i $fsimage_dir/$infile -o $oivexport_dir/fsimage-$namenode.csv
```

​
## Yarn
Yarn metrics can be scraped from Rest APIs as seen below. Getting data into 
Prometheus requires an exporter which emits metrics in the Prometheus format.

```
docker run -e YARN_PROMETHEUS_ENDPOINT_HOST=hostname \
  -e YARN_PROMETHEUS_LISTEN_ADDR=:9113  
  -p 9113:9113 pbweb/yarn-prometheus-exporter
```

* Example Yarn Rest API metrics scraped
```
curl -X GET "http://$resourcemanager:8080/ws/v1/cluster/metrics"
```

* Metrics returned:
```
	applicationsSubmitted
	applicationsCompleted
	applicationsPending   
	applicationsRunning   
	applicationsFailed    
	applicationsKilled    
	memoryReserved        
	memoryAvailable       
	memoryAllocated       
	memoryTotal           
	virtualCoresReserved  
	virtualCoresAvailable
	virtualCoresAllocated
	virtualCoresTotal    
	containersAllocated   
	containersReserved    
	containersPending     
	nodesTotal            
	nodesLost             
	nodesUnhealthy        
	nodesDecommissioned  
	nodesDecommissioning  
	nodesRebooted         
	nodesActive           
	scrapeFailures     
```

* For Running Applications
```
 docker run -e YARN_PROMETHEUS_ENDPOINT_HOST=hostname \
  -e YARN_PROMETHEUS_LISTEN_ADDR=:9120  -p 9120:9120 t3/yarnapp
```

* Metrics returned:
```
curl -X GET "http://$resourcemanager:8080/ws/v1/cluster/apps?state=running"

    Id string
    Name string
    User string
    Queue string
    State string
    FinalStatus string
    Progress float64
    TrackingUI string
    TrackingURL string
    Diagnostics string
    ClusterId float64
    ApplicationType string
    StartedTime float64
    FinishedTime float64
    ElapsedTime float64
    AmContainerLogs string
    AmHostHttpAddress string
    AllocatedMB float64
    AllocatedVCores float64
    ReservedMB float64
    ReservedVCores float64
    RunningContainers float64
    MemorySeconds float64
    VcoreSeconds float64
    PreemptedResourceMB float64
    PreemptedResourceVCores float64
    NumNonAMContainerPreempted float64
    NumAMContainerPreempted float64
    LogAggregationStatus string
``` 	
​

### Spark
Collecting Spark metrics can be accomplished using a Graphite sink which is 
native to Spark builds. 
​
```
docker run -d -p 9108:9108 -p 9109:9109 -p 9109:9109/udp \
  -v $PWD/graphite_mapping.conf:/tmp/graphite_mapping.conf \
  prom/graphite-exporter --graphite.mapping-config=/tmp/graphite_mapping.conf
```

​
#### Graphite Mapping file

```
mappings:
- match: '*.*.executor.filesystem.*.*'
  name: "filesystem_usage"
  labels:
    application: "$1"
    executor_id: "$2"
    fs_type: "$3"
    qty: "$4"
- match: '*.*.jvm.*.*'
  name: "jvm_memory_usage"
  labels:
    application: "$1"
    executor_id: "$2"
    mem_type: "$3"
    qty: "$4"
- match: '*.*.jvm.pools.*.*'
  name: "jvm_memory_pools"
  labels:
    application: "$1"
    executor_id: "$2"
    mem_type: "$3"
    qty: "$4"
- match: '*.*.executor.threadpool.*'
  name: "executor_tasks"
  labels:
    application: "$1"
    executor_id: "$2"
    qty: "$3"
- match: '*.*.BlockManager.*.*'
  name: "block_manager"
  labels:
    application: "$1"
    executor_id: "$2"
    type: "$3"
    qty: "$4"
- match: '*.*.DAGScheduler.*.*'
  name: "DAG_scheduler"
  labels:
    application: "$1"
    executor_id: "$2"
    type: "$3"
    qty: "$4"
- match: '*.*.CodeGenerator.*.*'
  name: "CodeGenerator"
  labels:
    application: "$1"
    executor_id: "$2"
    type: "$3"
    qty: "$4"
- match: '*.*.HiveExternalCatalog.*.*'
  name: "HiveExternalCatalog"
  labels:
    application: "$1"
    executor_id: "$2"
    type: "$3"
    qty: "$4"
- match: '*.*.ExecutorAllocationManager.*.*'
  name: "ExecutionAllocationManager"
  labels:
    application: "$1"
    executor_id: "$2"
    type: "$3"
    qty: "$4"
- match: '*.*.filesystem_usage.*.*'
  name: "filesystem_usage"
  labels:
     application: "$1"
     exported_job: "$2"
     fs_type: "$3"
- match: '*.*.executor_tasks.*.*'
  name: "executor_tasks"
  labels:
     application: "$1"
     qty: "$2"
```

​
#### Graphite Properties file
Distribute the following conf file to driver and all executor nodes. All should
be in same path **graphite.properties**

* Enable Prometheus for all instances by class name
```
*.sink.graphite.class=org.apache.spark.metrics.sink.GraphiteSink
*.sink.graphite.host=cloud-bdidev1
*.sink.graphite.port=9109
*.sink.prometheus.period=10
*.sink.prometheus.unit=SECONDS
#*.sink.prometheus.pushgateway-enable-timestamp=false
```

* Enable JVM metrics source for all instances by class name
```
master.source.jvm.class=org.apache.spark.metrics.source.JvmSource
worker.source.jvm.class=org.apache.spark.metrics.source.JvmSource
driver.source.jvm.class=org.apache.spark.metrics.source.JvmSource
executor.source.jvm.class=org.apache.spark.metrics.source.JvmSource
```
​
* Launch job with the following metrics configuration:
```
--conf spark.metrics.conf=/etc/spark2/conf/graphite.properties
```


#### MySQL
Collecting MySQL metrics is useful for keeping track of IO activity, slave
replication status and other useful metrics and acertaining the health of Hadoop
ecosystem as a whole. A community supported prometheus exporter has been added
and runs as docker process on reporting server.
​
* https://github.com/prometheus/mysqld_exporter  

```
docker run -d -p 9104:9104 \
-e DATA_SOURCE_NAME="<user>:<password>@(<host>:3306)/" \
prom/mysqld-exporter --no-collect.info_schema.tables --collect.info_schema.innodb_metrics
```


### Here is Prometheus itself.

```
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'yarn-bdi-np'
    #metrics_path: /ws/v1/cluster/metrics
    static_configs:
    - targets: ['localhost:9113']
  - job_name: 'yarn-bda-np'
    static_configs:
    - targets: ['localhost:9114']
  - job_name: 'yarn-bda-prod'
    static_configs:
    - targets: ['localhost:9115']
  - job_name: 'yarn-bdi-prod'
    static_configs:
    - targets: ['localhost:9116']
  - job_name: 'mysql-bda-np'
    scrape_interval: 300s
    static_configs:
    - targets: ['localhost:9104']
  - job_name: 'mysql-bda-np-repl'
    scrape_interval: 300s
    static_configs:
    - targets: ['localhost:9105']
  - job_name: 'mysql-bda-prod'
    scrape_interval: 300s
    static_configs:
    - targets: ['localhost:9106']
  - job_name: 'mysql-bda-prod-repl'
    scrape_interval: 300s
    static_configs:
    - targets: ['localhost:9107']
  - job_name: 'bdidev1-sparkprometheus'
    static_configs:
    - targets: ['clv0v5dl-dabeef:9108']
  - job_name: 'yarnapps-bda-prod'
    static_configs:
    - targets: ['localhost:9118']
  - job_name: 'yarnapps-bda-nonprod'
    static_configs:
    - targets: ['localhost:9119']
  - job_name: 'yarnapps-bdi-nonprod'
    static_configs:
    - targets: ['localhost:9120']
  - job_name: 'yarnapps-bdi-prod'
    static_configs:
    - targets: ['localhost:9121']
```
