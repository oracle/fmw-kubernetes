---
title: "Preparing OCIR"
date: 2019-09-21T15:44:42-05:00
draft: false
weight: 1
pre: "<b>1 c. </b>"
description: "Running WebLogic Kubernetes Operator managed Oracle WebCenter Contnet domains on OKE"
---

#### Publish images to OCIR
Push all the required images to OCIR and subsequently use from there. Follow the below steps for pushing the images to OCIR

#### Create an "Auth token"
Create an "Auth token" which will be used as docker password to push and pull images from OCIR.
Login to OCI Console and navigate to User Settings, which is in the drop down under your OCI user-profile, located at the top-right corner of the OCI console page.
![OCIR](images/ocir-image-1.PNG)
* On User Details page, Click `Auth Tokens` link located near bottom-left corner of the page and then Click the `Generate Token` button:
Enter a Name and Click "Generate Token"
![OCIR](images/ocir-imge-2.PNG)
![OCIR](images/ocir-image-3.PNG)
* Token will get generated
![OCIR](images/ocir-image-4.jpg)
* Copy the generated token. 
  > NOTE: It will only be displayed this one time, and you will need to copy it to a secure place for further use.

#### Using the OCIR
Using the Docker CLI to login to OCIR ( for phoenix : phx.ocir.io , ashburn: iad.ocir.io etc)
  1. docker login phx.ocir.io
  1. When promoted for username enter docker username as OCIR RepoName/oci username ( eg., axcmmdmzqtqb/oracleidentitycloudservice/myemailid@oracle.com)
  1. When prompted for your password, enter the generated Auth Token
  1. Now you can tag the WCC Docker image and push to OCIR. Sample steps as below

```bash
$ docker login phx.ocir.io
$ username - axcmmdmzqtqb/oracleidentitycloudservice/myemailid@oracle.com
$ password - abCXYz942,vcde     (Token Generated for OCIR using user setting)

$ docker tag
docker tag oracle/wccontent:12.2.1.4.0-20210311104247 phx.ocir.io/axcmmdmzqtqb/oracle/wccontent:12.2.1.4.0-20210311104247

$ docker push  docker push phx.ocir.io/axcmmdmzqtqb/oracle/wccontent:12.2.1.4.0-20210311104247
```
This has to be done on Bastion Node for all the images.

#### Verify the OCIR Images
Get the OCIR repository name by logging in to Oracle Cloud Infrastructure Console. In the OCI Console, open the Navigation menu. Under Solutions and Platform, go to Developer Services and click Container Registry (OCIR) and select the your Compartment.

![OCIR](images/ocir-verify-pushed-imges-5.PNG)



