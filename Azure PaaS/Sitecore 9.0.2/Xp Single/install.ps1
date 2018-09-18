# Ensure your PowerShell environment is already configured on your system
# Import-Module Azure -AllowClobber
# Import-Module AzureRM -AllowClobber
# Set-ExecutionPolicy Unrestricted

#Point to the sitecore cloud tools on your local filesystem
Import-Module "ABSOLUTE LOCAL PATH\Sitecore Azure Toolkit\tools\Sitecore.Cloud.Cmdlets.psm1"

#Add the azure account
Add-AzureRmAccount

#Fill in Parameters
$Name ="DEPLOYMENT ID"
$certfilelocation = "ABSOLUTE LOCAL PATH\YOURCERT.pfx"
$licensefilelocaiton = "ABSOLUTE LOCAL PATH\license.xml"
$ArmParametersPath = "ABSOLUTE LOCAL PATH\azuredeploy.parameters.json"
$ArmTemplateUrl = "URL for azuredeploy.json stored in public azure sotrage blob"
$AzureRegion = "AZURE REGION"

Start-SitecoreAzureDeployment -Location $AzureRegion -Name $Name -ArmTemplateUrl $ArmTemplateUrl -ArmParametersPath $ArmParametersPath -LicenseXmlPath $licensefilelocaiton -SetKeyValue @{"authCertificateBlob" = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($certfilelocation))} -Verbose
