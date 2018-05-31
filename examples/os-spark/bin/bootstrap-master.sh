#!/bin/bash

# Detect IP addresses
private_IPv4="$(ifconfig eth0 | awk '/inet / {print $2}')"
public_IPv4="$(curl -4 icanhazip.com)"
echo "Detected private IPv4: $private_IPv4"
echo "Detected public IPv4: $public_IPv4"

# Write Traefik configuration
mkdir -p /etc/traefik
cat << EOF > /etc/traefik/traefik.toml
defaultEntryPoints = ["http"]
[rest]
[api]
EOF

# Start Traefik
docker run --detach \
  --network host \
  --volume /etc/traefik/traefik.toml:/etc/traefik/traefik.toml \
  --restart always \
  traefik:1.6.2

# Start Spark master
docker run --detach \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --env "SPARK_MASTER_HOST=$private_IPv4" \
  --env "SPARK_PUBLIC_DNS=$${public_IPv4}.nip.io" \
  --env "SPARK_MASTER_WEBUI_PORT=8081"
  --network host \
  --add-host "$(hostname):127.0.0.1" \
  --restart always \
  "${spark_docker_image}" \
  bin/spark-class org.apache.spark.deploy.master.Master

# Configure Traefik UI fronted/backend
curl "http://localhost:8080/api/providers/rest" -XPUT -d @- << EOF
{
  "frontends": {
    "traefik": {
      "routes": {
        "traefik": {
          "rule": "Host:traefik.$${public_IPv4}.nip.io"
        }
      },
      "backend": "traefik"
    },
    "spark": {
      "routes": {
        "spark": {
          "rule": "Host:spark.$${public_IPv4}.nip.io"
        }
      },
      "backend": "spark"
    }
  },
  "backends": {
    "traefik": {
      "servers": {
        "server": {
          "URL": "http://localhost:8080"
        }
      }
    },
    "spark": {
      "servers": {
        "server": {
          "URL": "http://localhost:8081"
        }
      }
    }
  }
}
EOF
