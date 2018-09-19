# Sitecore XP Single Environment

This template creates a Sitecore XP Single Environment using a minimal set of Azure resources while still ensuring Sitecore will run. It is best practice to use this configuration for development and testing rather than production environments.

Resources provisioned:

  * Azure SQL databases : core, master, web, reporting, pools, tasks, forms, refdata, smm, shard0, shard1, ma
  * Sitecore roles: Content Delivery, Content Management, Processing, Reporting as a single WebApp instance
	  * Hosting plans: single hosting plan
	  * Preconfigured Web Application, based on the provided WebDeploy package
  * XConnect services: Search, Collection, Reference data, Marketing Automation, Marketing Automation Reporting as a single WebApp instance
	  * Hosting plans: single hosting plan
	  * Preconfigured Web Application, based on the provided WebDeploy package
  * Azure Search Service
  * Application Insights for diagnostics and monitoring
  * Modules
      * Module Bootloader
	  * SPE and SXA 

## Parameters

|Parameter                                  | Description
|-------------------------------------------|---------------------------------------------------------------------------------------------
| deploymentId                              | Resource group name.
| location                                  | The geographical region of the current deployment.
| sitecoreAdminPassword                     | The new password for the Sitecore **admin** account.
| sqlServerLogin                            | The name of the administrator account for Azure SQL server that will be created. SA is not a valid login
| sqlServerPassword                         | The password for the administrator account for Azure SQL server.
| singleMsDeployPackageUrl                  | The HTTP(s) URL with SASto a Sitecore XP Single Web Deploy package.
| xcSingleMsDeployPackageUrl                | The HTTP(s) URL with SAS to a XConnect Single Web Deploy package.
| authCertificateBlob                       | A Base64-encoded blob of the authentication certificate in PKCS #12 format.
| authCertificatePassword                   | A password to the authentication certificate.

## Modules

[Sitecore Azure Modules Dcoumentation](https://github.com/Sitecore/Sitecore-Azure-Quickstart-Templates/blob/master/MODULES.md)
[SPE and SXA Dcoumentation](https://github.com/Sitecore/Sitecore-Azure-Quickstart-Templates/tree/master/SXA%201.7.1/xp0)

> **Note:**
> * The **searchServiceLocation** parameter can be added to the `azuredeploy.parameters.json`
> to specify geographical region to deploy Azure Search Service. Default value is the resource
> group location.
> * The **applicationInsightsLocation** parameter can be added to the`azuredeploy.parameters.json`
> to specify geographical region to deploy Application Insights. Default value is **East US**.
> * The **allowInvalidClientCertificates** has been parameter added to allow self signed certificates