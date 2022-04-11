## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# Configure the cluster with kube-config

resource "null_resource" "cluster_kube_config" {

  count = var.provision_cluster ? 1 : 0

  depends_on = [module.node_pools, module.cluster]

  provisioner "local-exec" {
    command = templatefile("./templates/cluster-kube-config.tpl",
      {
        cluster_id = module.cluster.cluster.id
        region     = var.region
    })
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete all --all --force"
    on_failure = continue
  }
}

# Create the cluster-admin user to use with the kubernetes dashboard

resource "null_resource" "oke_admin_service_account" {
  count = var.provision_cluster && var.oke_cluster["cluster_options_add_ons_is_kubernetes_dashboard_enabled"] ? 1 : 0

  depends_on = [null_resource.cluster_kube_config]

  provisioner "local-exec" {
    command = "kubectl create -f ./templates/oke-admin.ServiceAccount.yaml"
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete ServiceAccount oke-admin -n kube-system"
    on_failure = continue
  }
}

# Create the namespace for the WebLogic Operator

resource "null_resource" "create_wls_operator_namespace" {
  count = var.provision_weblogic_operator ? 1 : 0

  depends_on = [null_resource.cluster_kube_config]

  triggers = {
    weblogic_operator_namespace = var.weblogic_operator_namespace
  }

  provisioner "local-exec" {
    command = "kubectl create namespace ${var.weblogic_operator_namespace}"
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete all -n ${self.triggers.weblogic_operator_namespace} --force && kubectl delete namespace ${self.triggers.weblogic_operator_namespace}"
    on_failure = continue
  }
}

# Create the namespace for the Sites deployment
resource "null_resource" "create_sites_namespace" {
  depends_on = [null_resource.cluster_kube_config]

  triggers = {
    sites_kubernetes_namespace = var.sites_kubernetes_namespace
  }

  provisioner "local-exec" {
    command = "kubectl create namespace ${var.sites_kubernetes_namespace}"
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete all -n ${self.triggers.sites_kubernetes_namespace} --force && kubectl delete namespace ${self.triggers.sites_kubernetes_namespace}"
    on_failure = continue
  }
}

# Create the user secret to use to pull docker images from Oracle Container Registry

resource "null_resource" "docker_registry" {

  depends_on = [null_resource.cluster_kube_config, null_resource.create_sites_namespace]

  triggers = {
    sites_kubernetes_namespace = var.sites_kubernetes_namespace
  }

  provisioner "local-exec" {
    command = templatefile("./templates/docker-registry-secret.tpl",
      {
        username     = var.container_registry_username
        email     = var.container_registry_email
        password  = var.container_registry_password
        namespace = var.sites_kubernetes_namespace
        repository = var.container_registry
    })
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete secret image-secret -n ${self.triggers.sites_kubernetes_namespace}"
    on_failure = continue
  }
}

# Create the namespace for the Traefik deployment
resource "null_resource" "create_traefik_namespace" {

  count = var.provision_traefik ? 1 : 0

  depends_on = [null_resource.cluster_kube_config]

  triggers = {
    ingress_namespace = var.ingress_controller_namespace
  }

  provisioner "local-exec" {
    command = "if [[ ! $(kubectl get ns ${var.ingress_controller_namespace}) ]]; then kubectl create namespace ${var.ingress_controller_namespace}; fi"
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete namespace ${self.triggers.ingress_namespace}"
    on_failure = continue
  }
}

# Deploy the Kubernetes Operator helm chart

resource "null_resource" "deploy_wls_operator" {

  count = var.provision_weblogic_operator ? 1 : 0

  depends_on = [null_resource.create_wls_operator_namespace, null_resource.create_sites_namespace]

  triggers = {
    weblogic_operator_namespace = var.weblogic_operator_namespace
    sites_namespace               = var.sites_kubernetes_namespace
  }

  provisioner "local-exec" {
    command = templatefile("./templates/deploy-weblogic-operator.tpl", {
      weblogic_operator_namespace = var.weblogic_operator_namespace
      sites_namespace               = var.sites_kubernetes_namespace
    })
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "helm delete weblogic-operator --namespace ${self.triggers.weblogic_operator_namespace} && kubectl delete crds domains.weblogic.oracle"
    on_failure = continue
  }
}

# Deploy the Traefik helm chart

resource "null_resource" "deploy_traefik" {
  count = var.provision_traefik ? 1 : 0

  depends_on = [null_resource.create_traefik_namespace, null_resource.create_sites_namespace]

  triggers = {
    ingress_namespace = var.ingress_controller_namespace
    sites_namespace     = var.sites_kubernetes_namespace
  }

  provisioner "local-exec" {
    command = templatefile("./templates/deploy-traefik.tpl", {
      ingress_namespace = var.ingress_controller_namespace
      sites_namespace     = var.sites_kubernetes_namespace
    })
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "helm delete traefik --namespace ${self.triggers.ingress_namespace}"
    on_failure = continue
  }
}

# Update ingress hostname in fromtf.auto.yaml

resource "null_resource" "get_ingress_hostname" {
  count = var.provision_traefik ? 1 : 0

  depends_on = [null_resource.create_traefik_namespace, null_resource.create_sites_namespace, null_resource.deploy_traefik]

  triggers = {
    ingress_namespace = var.ingress_controller_namespace
  }

  provisioner "local-exec" {
    command = templatefile("./templates/ingress-hostname.tpl", {
      ingress_namespace = var.ingress_controller_namespace
    })
  }
}

# Create secrets
resource "null_resource" "create_sites_domain_secret" {
  count = var.provision_secrets ? 1 : 0

  depends_on = [null_resource.create_sites_namespace]

  triggers = {
    name      = "${var.sites_domain_name}-domain-credentials"
    namespace = var.sites_kubernetes_namespace
    username  = var.sites_domain_admin_username
    password  = var.sites_domain_admin_password
  }

  provisioner "local-exec" {
    command = templatefile("./templates/create_secret.tpl", {
      name      = "${var.sites_domain_name}-domain-credentials"
      namespace = var.sites_kubernetes_namespace
      username  = var.sites_domain_admin_username
      password  = var.sites_domain_admin_password
    })
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete secret ${self.triggers.name} --namespace ${self.triggers.namespace}"
    on_failure = continue
  }
}

resource "null_resource" "create_rcu_secret" {
  count = var.provision_secrets ? 1 : 0

  depends_on = [null_resource.create_sites_namespace]

  triggers = {
    name      = "${var.sites_domain_name}-rcu-credentials"
    namespace = var.sites_kubernetes_namespace
    username  = var.provision_adb ? var.adb_username : var.rcu_username
    password  = var.provision_adb ? var.adb_password : var.rcu_password
    sys_username  = var.provision_adb ? var.adb_username : var.db_sys_username
    sys_password  = var.provision_adb ? var.adb_password : var.db_sys_password
    domainUID  = var.sites_domain_name
  }

  provisioner "local-exec" {
    command = templatefile("./templates/create-rcu-credentials.tpl", {
      name      = "${var.sites_domain_name}-rcu-credentials"
      namespace = var.sites_kubernetes_namespace
      username  = var.provision_adb ? var.adb_username : var.rcu_username
      password  = var.provision_adb ? var.adb_password : var.rcu_password
      sys_username  = var.provision_adb ? var.adb_username : var.db_sys_username
      sys_password  = var.provision_adb ? var.adb_password : var.db_sys_password
      domainUID  = var.sites_domain_name
    })
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete secret ${self.triggers.name} --namespace ${self.triggers.namespace}"
    on_failure = continue
  }
}

resource "null_resource" "create_db_secret" {
  count = var.provision_secrets ? 1 : 0

  depends_on = [null_resource.create_sites_namespace]

  triggers = {
    name      = "${var.sites_domain_name}-db-credentials"
    namespace = var.sites_kubernetes_namespace
    username  = var.provision_adb ? var.adb_username : "SYS"
    password  = var.provision_adb ? var.adb_password : var.db_sys_password
  }

  provisioner "local-exec" {
    command = templatefile("./templates/create_secret.tpl", {
      name      = "${var.sites_domain_name}-db-credentials"
      namespace = var.sites_kubernetes_namespace
      username  = var.provision_adb ? var.adb_username : "SYS"
      password  = var.provision_adb ? var.adb_password : var.db_sys_password
    })
  }
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete secret ${self.triggers.name} --namespace ${self.triggers.namespace}"
    on_failure = continue
  }
}


# Deploy the Sites Suite helm chart
resource "null_resource" "deploy_sites" {
  count = var.provision_sites ? 1 : 0

  depends_on = [
    null_resource.deploy_wls_operator,
    null_resource.deploy_traefik,
    null_resource.get_ingress_hostname,
    module.database,
    null_resource.docker_registry,
    null_resource.create_db_secret,
    null_resource.create_rcu_secret,
    null_resource.create_sites_domain_secret,
    local_file.helm_values
  ]

  triggers = {
    sites_domain_name   = var.sites_domain_name
    sites_domain_type   = var.sites_domain_type
    sites_namespace     = var.sites_kubernetes_namespace
    sites_domain_secret = "${var.sites_domain_name}-domain-credentials"
    rcu_prefix        = var.rcu_prefix
    rcu_secret        = "${var.sites_domain_name}-rcu-credentials"
    db_secret         = "${var.sites_domain_name}-db-credentials"
    jdbc_connection_url = var.jdbc_connection_url != null ? var.jdbc_connection_url : var.provision_adb ? module.oci-adb.connection_urls : module.database.jdbc_connection_url
    # db_sys_password     = var.db_sys_password
    nfs_server_ip = var.mount_target_ip !=null ? var.mount_target_ip : module.fss.server_ip
    path          = module.fss.path
  }

  provisioner "local-exec" {
    command = templatefile("./templates/deploy-sites.tpl", {
      sites_domain_name   = var.sites_domain_name
      sites_domain_type   = var.sites_domain_type
      sites_namespace     = var.sites_kubernetes_namespace
      sites_domain_secret = "${var.sites_domain_name}-domain-credentials"
      rcu_prefix        = var.rcu_prefix
      rcu_secret        = "${var.sites_domain_name}-rcu-credentials"
      db_secret         = "${var.sites_domain_name}-db-credentials"
      jdbc_connection_url = var.jdbc_connection_url != null ? var.jdbc_connection_url : var.provision_adb ? module.oci-adb.connection_urls : module.database.jdbc_connection_url
      # db_sys_password     = var.db_sys_password
      nfs_server_ip = module.fss.server_ip
      path          = module.fss.path
    })
  }
  provisioner "local-exec" {
    when = destroy
    command = templatefile("./templates/undeploy-sites.tpl", {
      sites_domain_name = self.triggers.sites_domain_name
      sites_namespace   = self.triggers.sites_namespace
    })
    on_failure = continue
  }
}
