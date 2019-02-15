#!/bin/bash
#


( docker start tdh-mysql1 )

( docker start tdh-prometheus1 )

( docker start tdh-grafana1 )

( docker start tdh-hdfs-exporter1 )

( docker start tdh-yarn-exporter1 )

( docker start tdh-spark-exporter1 )

( docker start tdh-mysql-exporter1 )

