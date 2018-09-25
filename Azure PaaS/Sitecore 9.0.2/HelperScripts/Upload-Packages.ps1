###############################################
# Upload created WDPs during the build in Azure

# Set variables for the container names
$containerName = "azure-toolkit"
$additionalContainerName = "temporary-toolkit"

# Check the Azure PowerShell Module's version
$AzureModule = Get-Module -ListAvailable AzureRM
if ($AzureModule -eq ""){

# If the Azure PowerShell module is not present, install the module
    Install-Module -Name AzureRM

}

# Import the module into the PowerShell session
Import-Module AzureRM

# Connect to Azure with an interactive dialog for sign-in
Connect-AzureRmAccount

# Get the current storage account
$sa = Get-AzureRmStorageAccount

# Obtain the storage account context
$ctx = $sa.Context

# Try to write to the container - if failing, use a temporary one
try {

	# Check if the container name already exists
    Get-AzureStorageContainer -Container $containerName -Context $ctx

	# Remove the temporary container if it exists
    Remove-AzureStorageContainer -Name "$additionalContainerName" -Context $ctx -Force

    # Create the main container for the WDPs
    New-AzureStorageContainer -Name $containerName -Context $ctx -Permission blob

    # Upload the WDP modules to the blob container
    Get-ChildItem -Path "C:\_deployment\website_packaged\convert to WDP\WPD\" -Recurse | Set-AzureStorageBlobContent -Container $containerName -Context $ctx -Force

}
catch {

	# Remove the main container if the previous attempt has failed to create it
    Remove-AzureStorageContainer -Name "$containerName" -Context $ctx -Force

    # Create a temporary container 
    New-AzureStorageContainer -Name $additionalContainerName -Context $ctx -Permission blob

    # Upload the WDP modules to the temporary blob container
    Get-ChildItem -Path "C:\_deployment\website_packaged\convert to WDP\WPD\" -Recurse | Set-AzureStorageBlobContent -Container $additionalContainerName -Context $ctx
    
}

# Assign values to the blobs


# Get the URL for each blob and assign it to a variable
(Get-AzureStorageBlob -blob 'StarterSite.zip' -Container $containerName).ICloudBlob.uri.AbsoluteUri

#######################################
# Construct azuredeploy.parameters.json

$cake_config = Get-Content 'C:\Users\auzunov\Source\Repos\HabitatHome-Azure-PaaS\Azure PaaS\Cake\cake-config.json' -raw | ConvertFrom-Json
$deployemtId = $cake_config.AzureDeploymentID
$location = $cake_config.AzureGeoLocation
$sitecoreAdminPassword = $cake_config.SitecoreLoginAdminPassword
$licenseXml = $cake_config.SitecoreLicenseXMLPath
$sqlServerLogin = $cake_config.SqlServerLoginAdminAccount
$sqlServerPassword = $cake_config.SqlServerLoginAdminPassword
$authCertificatePassword = $cake_config.XConnectCertificatePassword

$azuredeploy_template = Get-Content 'C:\Users\auzunov\Downloads\ARM_deploy\!Deployment\Azure PaaS\Sitecore 9.0.2\Xp Single\azuredeploy.parameters.json' -raw | ConvertFrom-Json
$azuredeploy_template.parameters | % {
    $_.deploymentId.value = $deployemtId
    $_.location.value = $location
    $_.sitecoreAdminPassword.value = $sitecoreAdminPassword
    $_.licenseXml.value = $licenseXml
    $_.sqlServerLogin.value = $sqlServerLogin
    $_.sqlServerPassword.value = $sqlServerPassword
    $_.authCertificatePassword.value = $authCertificatePassword
    $_.singleMsDeployPackageUrl.value = $singleMsDeployPackageUrl
    $_.xcSingleMsDeployPackageUrl.value = $xcSingleMsDeployPackageUrl
    $_.modules.value.items.parameters.sxaMsDeployPackageUrl = $sxaMsDeployPackageUrl
    $_.modules.value.items.parameters.speMsDeployPackageUrl = $speMsDeployPackageUrl
    $_.modules.value.items.parameters.defDeployPackageUrl = $defDeployPackageUrl
    $_.modules.value.items.parameters.defSitecoreDeployPackageUrl = $defSitecoreDeployPackageUrl
    $_.modules.value.items.parameters.defSqlDeployPackageUrl = $defSqlDeployPackageUrl
    $_.modules.value.items.parameters.defxConnectDeployPackageUrl = $defxConnectDeployPackageUrl
    $_.modules.value.items.parameters.defDynamicsDeployPackageUrl = $defDynamicsDeployPackageUrl
    $_.modules.value.items.parameters.defDynamicsConnectDeployPackageUrl = $defDynamicsConnectDeployPackageUrl
    $_.modules.value.items.parameters.msDeployPackageUrl = $msDeployPackageUrl

    if ($_.modules.value.items.name = "sxa"){

        $_.modules.value.items.templateLink = $sxaTemplateLink
    
    } elseif ($_.modules.value.items.name = "def"){
    
        $_.modules.value.items.templateLink = $defTemplateLink
    
    } elseif ($_.modules.value.items.name = "bootloader"){
    
        $_.modules.value.items.templateLink = $bootloaderTemplateLink
    
    }

}
$azuredeploy_template | ConvertTo-Json -Depth 20 | Set-Content 'C:\Users\auzunov\Downloads\ARM_deploy\!Deployment\Azure PaaS\Sitecore 9.0.2\Xp Single\azuredeploy.parameters - Copy.json'