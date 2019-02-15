#!/bin/bash
#

( docker stop tdh-hdfs-exporter1 )

( docker stop tdh-yarn-exporter1 )

( docker stop tdh-spark-exporter1 )

( docker stop tdh-mysql-exporter1 )

( docker stop tdh-grafana1 )

( docker stop tdh-prometheus1 )

( docker stop tdh-mysql1 )
