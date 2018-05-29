#!/bin/bash

# Detect IP addresses
private_IPv4="$(ifconfig eth0 | awk '/inet / {print $2}')"
public_IPv4="$(curl -4 icanhazip.com)"
echo "Detected private IPv4: $private_IPv4"
echo "Detected public IPv4: $public_IPv4"

# Start Spark master
docker run --detach \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --env "SPARK_MASTER_HOST=$private_IPv4" \
  --env "SPARK_PUBLIC_DNS=$${public_IPv4}.nip.io" \
  --network host \
  --add-host "$(hostname):127.0.0.1" \
  --restart always \
  "${spark_docker_image}" \
  bin/spark-class org.apache.spark.deploy.master.Master

# Start Traefik
mkdir -p /etc/traefik
cat << EOF > /etc/traefik/conf.toml
# Entry points
defaultEntryPoints = ["http"]

[entryPoints]
  [entryPoints.http]
  address = ":80"

# Rules
[file]

[backends]

EOF