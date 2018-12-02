TDH-Docker - Version 0.21
=========================


  A collection of docker containers for supporting TDH.


# Hadoop Metrics
 A set of containers for deploying Prometheus for collecting various hadoop metrics.

​
## HDFS
HDFS filesystem analysis can be performed through the extraction of fsimage files
from the  NameNode server via rest API call. The fsimage file is
run through an offline image viewer which can convert block info to csv format
for import into RDBMS, I used MySQL.

* FSImage Retrieval
```
curl -X GET "http://$nn:50070/imagetransfer?getimage=1&txid=latest" --output $outfile
```

* FSImage conversion to CSV
```
hdfs oiv  -p Delimited -delimiter "," -i $fsimage_dir/$infile \
-o $oivexport_dir/fsimage-$namenode.csv
```

## Yarn
Yarn metrics can be scraped from Rest APIs as seen below. Getting data into
Prometheus requires an exporter which emits metrics in the Prometheus format.
This makes use of the YARN Prometheus exporter:

*https://github.com/PBWebMedia/yarn-prometheus-exporter*

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

## Spark
Collecting Spark metrics can be accomplished using a Graphite sink which is
native to Spark builds.

#### Graphite Properties file
Distribute the following conf file to driver and all executor nodes. All should
be in same path *graphite.properties*

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

* Launch job with the following metrics configuration:
```
--conf spark.metrics.conf=/etc/spark2/conf/graphite.properties
```

## MySQL
Collecting MySQL metrics is useful for keeping track of IO activity, slave
replication status and other useful metrics and ascertaining the health of Hadoop
ecosystem as a whole. A community supported Prometheus exporter has been added
and runs as docker process on reporting server.

* https://github.com/prometheus/mysqld_exporter  

```
docker run -d -p 9104:9104 \
-e DATA_SOURCE_NAME="<user>:<password>@(<host>:3306)/" \
prom/mysqld-exporter --no-collect.info_schema.tables --collect.info_schema.innodb_metrics
```
