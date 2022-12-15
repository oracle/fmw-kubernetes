Oracle SOASuite Deploy tooling
==============================

The Oracle SOASuite Deploy tooling is developed extending `WebLogic Deploy tooling` python libraries to deploy Oracle SOA composites and Oracle Service Bus applications. The tool uses model and archive similar to `WebLogic Deploy tooling` for deploying Oracle SOA composites/Oracle Service Bus applications. The tool can be used only in online mode. The Administration and managed servers have to up running while you execute the tool.

### Package Oracle SOASuite Deploy tooling

Apache Maven is required for packaging the Oracle SOASuite Deploy tooling. Change directory to folder `FMWDeployTooling/OracleSOASuite/soasuitedeploy/installer` and execute `mvn package` to generate the package.

```bash
$ cd FMWDeployTooling/OracleSOASuite/soasuitedeploy/installer
$ mvn package
```
The package will be generated in folder `FMWDeployTooling/OracleSOASuite/soasuitedeploy/installer/target/`.

### Model

Below a sample model for deploying Oracle SOA composites and Oracle Service Bus applications. The model lists out the composites and applications in respective 'SOAComposites' and 'OSBApplications' sections.

```yaml
soaDeployments:
    SOAComposites:
        GenesisSyncAccountSample:
            SourcePath: 'wlsdeploy/soa/sca_GenesisSyncAccountSample.jar'
        SimpleBPELProj:
            SourcePath: 'wlsdeploy/soa/sca_SimpleBPELProj.jar'
    OSBApplications:
        simple:
            SourcePath: 'wlsdeploy/osb/simple_sbconfig.jar'
        LargeMessageSys:
            SourcePath: 'wlsdeploy/osb/LargeMessageSys_sbconfig.jar'
        HelloWorld:
            SourcePath: 'wlsdeploy/osb/HelloWorld_sbconfig.jar'
```

### Archive

The archive file should have the composites and application binaries that needs to be deployed and listed in the model. The root folder in the archive should be 'wlsdeploy'. There can be child folders from the root folder. A sample archive can be as below,

```bash
$ unzip -l soaapps.zip
Archive:  soaapps.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  08-29-2022 00:28   wlsdeploy/
        0  08-29-2022 00:29   wlsdeploy/soa/
   353360  08-29-2022 00:29   wlsdeploy/soa/sca_GenesisSyncAccountSample.jar
    23590  08-29-2022 00:29   wlsdeploy/soa/sca_SimpleBPELProj.jar
---------                     -------
   376950                     4 files
```

### Deploy Oracle Service Bus Applications

The tool requires the mandatory arguments to be passed to tool,

* Oracle home.
* Domain home.
* Model file.
* Archive file containing Oracle Service Bus application binaries.
* URL to the Administration server.
* Administration username.

```bash
$ soasuitedeploy/bin/deployer.sh  -oracle_home /u01/oracle \
                                -domain_home /u01/oracle/user_projects/domains/soainfra \
                                -model_file ./osbcomp-model.yaml \
                                -archive_file ./osbcomps.zip \
                                -admin_url t3://soainfra-adminserver.soans.svc.cluster.local:7001 \
                                -admin_user weblogic
```

The tool will request for 'Administration' user password. On providing the password, the tool will deploy the applications.

### Deploy Oracle SOA Composites

The tool requires the mandatory arguments to be passed to tool,

* Oracle home.
* Domain home.
* Model file.
* Archive file containing Oracle SOA composite binaries.
* URL to the Administration server.
* URL to SOA cluster/managed server.
* Administration username.

```bash
$ soasuitedeploy/bin/deployer.sh  -oracle_home /u01/oracle \
                                -domain_home /u01/oracle/user_projects/domains/soainfra \
                                -model_file soa-apps.yaml \
                                -archive_file soaapps.zip \
                                -admin_url t3://soainfra-adminserver.soans.svc.cluster.local:7001 \
                                -soa_url http://soainfra-soacluster.soans.svc.cluster.local:8001 \
                                -admin_user weblogic
```

Note:- In case of deploying SOA composites, will require additional parameter of 'soa_url'.
