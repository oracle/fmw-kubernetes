---
title: "Deploy using JDeveloper"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 1
pre : "<b>a. </b>"
description: "Deploy Oracle SOA Suite and Oracle Service Bus composite applications from Oracle JDeveloper to Oracle SOA Suite in the WebLogic Kubernetes operator environment."
---

Learn how to deploy Oracle SOA Suite and Oracle Service Bus composite applications from Oracle JDeveloper (running outside the Kubernetes network) to an Oracle SOA Suite instance in the WebLogic Kubernetes operator environment.

{{% notice note %}}
Use JDeveloper for development and test environments only. For a production environment, you should deploy using Application Control and WLST methods.
{{% /notice %}}

### Deploy Oracle SOA Suite and Oracle Service Bus composite applications to Oracle SOA Suite from JDeveloper

To deploy Oracle SOA Suite and Oracle Service Bus composite applications from Oracle JDeveloper, the Administration Server must be configured to expose a T3 channel. The WebLogic Kubernetes operator provides an option to expose a T3 channel for the Administration Server using the `exposeAdminT3Channel` setting during domain creation, then the matching T3 service can be used to connect. By default, when `exposeAdminT3Channel` is set, the WebLogic Kubernetes operator environment exposes the  `NodePort` for the T3 channel of the `NetworkAccessPoint` at `30012` (use `t3ChannelPort` to configure the port to a different value).

If you miss enabling `exposeAdminT3Channel` during domain creation, follow [Expose a T3/T3S Channel for the Administration Server]({{< relref "/soa-domains/adminguide/enablingt3#expose-t3t3s-for-administration-server" >}})  to expose a T3 channel manually.

![SOA Composite Deployment Model](/fmw-kubernetes/images/soa-domains/SOA_Composites_Deploy_using_Jdev.png)

#### Prerequisites

1. Get the Kubernetes cluster master address and verify the T3 port that will be used for creating application server connections. Use the following command to get the T3 port:
   ```
   $ kubectl get service <domainUID>-<AdministrationServerName>-external -n  <namespace>-o jsonpath='{.spec.ports[0].nodePort}'
   ```
   For example:
   ```
   $ kubectl get service soainfra-adminserver-external -n  soana-o jsonpath='{.spec.ports[0].nodePort}'
   ```

1. Oracle SOA Suite in the WebLogic Kubernetes operator environment is deployed in a *Reference Configuration domain*. If a SOA project is developed in Classic mode JDeveloper displays a Mismatch notification in the Deploy Composite Wizard.  By default, JDeveloper is in Classic mode. To develop SOA projects in Reference Configuration mode, you must manually enable this feature in JDeveloper:
   a. From the File menu, select **Tools**, then **Preferences**.
   b. Select **Reference Configuration Settings**.
   c. Select **Enable Reference Configuration settings in adapters**.

    ![Enable Reference Configuration](/fmw-kubernetes/images/soa-domains/JDEV_Reference_Config_Settings.png)


1. JDeveloper needs to access the Servers during deployment. In the WebLogic Kubernetes operator environment, Administration and Managed Servers are pods and cannot be accessed directly by JDeveloper. As a workaround, you must configure the reachability of the Managed Servers:

   {{% notice note %}} The Managed Server T3 port is not exposed by default and opening this will have a security risk as the authentication method here is based on a userid/password. It is not recommended to do this on production instances.
   {{% /notice %}}

   * Decide on an external IP address to be used to configure access to the Managed Servers. Master or worker node IP address can be used to configure Managed Server reachability. In these steps, the Kubernetes cluster master IP is used for demonstration.

   * Get the pod names of the Administration Server and Managed Servers (that is, `<domainUID>-<server name>`), which will be used to map in `/etc/hosts`.

   * Update `/etc/hosts` (or in Windows, `C:\Windows\System32\Drivers\etc\hosts`) on the host where JDeveloper is running with the entries below, where
     ```
     <Master IP> <Administration Server pod name>
     <Master IP> <Managed Server1 pod name>
     <Master IP> <Managed Server2 pod name>
     ```
     Sample /etc/hosts entries looks as follows, where `X.X.X.X` is the master node IP address:
     ```
     X.X.X.X soainfra-adminserver
     X.X.X.X soainfra-soa-server1  
     X.X.X.X soainfra-soa-server2
     ```
   * Get the Kubernetes service name of the Oracle SOA Suite cluster to access externally with the master IP (or external IP):
     ```
     $ kubectl get service <domainUID>-cluster-<soa-cluster> -n <namespace>
     ```
     For example:
     ```
     $ kubectl get service soainfra-cluster-soa-cluster -n soans
     ```
   * Create a Kubernetes service to expose the Oracle SOA Suite cluster service (`<domainUID>-cluster-<soa-cluster>`) externally with same port as the Managed Server:
     ```
     $ kubectl expose service  <domainUID>-cluster-<soa-cluster> --name <domainUID>-<soa-cluster>-ext --external-ip=<Master IP> -n <namespace>
     ```
     For example:
     ```
     $ kubectl expose service  soainfra-cluster-soa-cluster --name soainfra-cluster-soa-cluster-ext --external-ip=X.X.X.X -n soans
     ```
     {{% notice warning %}} In a production environment, exposing the SOA cluster service with an external IP address is not recommended, as it can cause message drops on the SOA Managed Servers.  
     {{% /notice %}} 

#### Create an application server connection in JDeveloper

1. Create a new application server connection (for example `wls-k8s-op-connection`) in JDeveloper:
    ![Create Application Server Connection](/fmw-kubernetes/images/soa-domains/CreateApplicationServerConnection.jpg)

1. In the configuration page, provide the WebLogic Hostname as the Kubernetes Master Address.
1. Update the Port as the T3 port (default is `30012`) obtained in [Prerequisites]({{< relref "/soa-domains/adminguide/deploying-composites/supportjdev#prerequisites" >}}).
1. Enter the WebLogic Domain value (`domainUID`).
1. Test the connection to verify it is successful.
    ![Create Application Server Connection](/fmw-kubernetes/images/soa-domains/CreateApplicationServerConnectionTestConnection.jpg)


#### Deploy SOA composite applications using JDeveloper

1. In JDeveloper, right-click the SOA project you want to deploy and select **Deploy** to display the deployment wizard.
    ![Deploy Project](/fmw-kubernetes/images/soa-domains/JDEV_SOA_Deployment_Start.png)

1. In the Deployment Action page, select **Deploy to Application Server** and click **Next**.
    ![Deployment Action](/fmw-kubernetes/images/soa-domains/JDEV_SOA_Select_Deployment_Action.png)

1. In the Deployment Configuration page, select the appropriate options and click **Next**.
    ![Deployment Configuration](/fmw-kubernetes/images/soa-domains/JDEV_SOA_Deploy_Configuration.png)

1. In the Select server page, select the application server connection (`wls-k8s-op-connection`) that was created earlier and click **Next**.
    ![Application Servers](/fmw-kubernetes/images/soa-domains/JDEV_SOA_Select_Application_Server.png)

1. If the [Prerequisites]({{< relref "/soa-domains/adminguide/deploying-composites/supportjdev#prerequisites" >}}) were configured correctly, the lookup discovers the Managed Servers for deploying the composite.
    ![Look Up Server](/fmw-kubernetes/images/soa-domains/JDEV_SOA_Server_Lookup.png)

1. Using the application server connection, the Managed Servers (Oracle SOA Suite cluster) are listed on the SOA Servers page. Select the Oracle SOA Suite cluster and click **Next**.
    ![Target Server](/fmw-kubernetes/images/soa-domains/JDEV_SOA_Target_soa_servers.png)

1. On the Summary page, click **Finish** to start deploying the composites to the Oracle SOA Suite cluster.
    ![Deploy Summary](/fmw-kubernetes/images/soa-domains/JDEV_SOA_Deployment_Summary.png)

    ![Deploying Progress](/fmw-kubernetes/images/soa-domains/JDEV_SOA_Deploying_Progress.png)

1. Verify logs on JDeveloper to confirm successful deployment.
    ![Deploying Status](/fmw-kubernetes/images/soa-domains/JDEV_SOA_Deploy_Success_Status.png)

1. Enter the soa-infra URLs in a browser to confirm the composites are deployed on both servers of the Oracle SOA Suite cluster.
    ![SOA URL 1](/fmw-kubernetes/images/soa-domains/JDEV_SOA_soainfra_server1.png)

    ![SOA URL 2](/fmw-kubernetes/images/soa-domains/JDEV_SOA_soainfra_server2.png)

#### Deploy Oracle Service Bus composite applications using JDeveloper

1. In JDeveloper, right-click the Oracle Service Bus project you want to deploy and select **Deploy** to display the deployment wizard.
    ![Deploy Project](/fmw-kubernetes/images/soa-domains/JDEV_OSB_Deployment_Start.png)

1. In the Deployment Action page, select **Deploy to Application Server** and click **Next**.
    ![Deployment Action](/fmw-kubernetes/images/soa-domains/JDEV_OSB_Select_Deployment_Action.png)

1. In the Select Server page, select the application server connection (`wls-k8s-op-connection`) that was created earlier and click **Next**.
    ![Application Servers](/fmw-kubernetes/images/soa-domains/JDEV_OSB_Select_Application_Server.png)

1. On the Summary page, click **Finish** to start deploying the composites to the Oracle Service Bus cluster.
    ![Deploy Summary](/fmw-kubernetes/images/soa-domains/JDEV_OSB_Deployment_Summary.png)

    ![Deploying Progress](/fmw-kubernetes/images/soa-domains/JDEV_OSB_Deploying_Progress.png)

1. In JDeveloper, verify logs to confirm successful deployment.
    ![Deploying Status](/fmw-kubernetes/images/soa-domains/JDEV_OSB_Deploy_Success_Status.png)

1. In the Oracle Service Bus Console, click **Launch Test Console** to verify that the Oracle Service Bus composite application is deployed successfully.
    ![Service Bus console](/fmw-kubernetes/images/soa-domains/JDEV_OSB_servicebus_launch_test_console.png)
