## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

imagePullSecrets: 
  - name: image-secret

image:
  name: ${container_registry_image}

oracledb:
  provision: false
  credentials:
    secretName: ${db_secret}
  url: ${jdbc_connection_url}

domain:
  domainName: ${sites_domain_name}
  type: ${sites_domain_type}
  credentials: 
    secretName: ${sites_domain_secret}
  rcuSchema:
    prefix: ${rcu_prefix}
    credentials:
      secretName: ${rcu_secret}
  storage:
    path: ${path}
    nfs:
      server: ${nfs_server_ip}

ingress:
  type: traefik
  tls: false
  hostname: ""
  dnsname: ${sites_dns_name}