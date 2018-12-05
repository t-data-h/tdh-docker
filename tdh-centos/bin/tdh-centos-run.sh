#!/bin/bash


( docker run -v /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -p 2202:22 -ti tdh:latest )

