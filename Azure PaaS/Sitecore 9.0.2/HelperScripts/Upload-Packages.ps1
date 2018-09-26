###############################################
# Upload created WDPs during the build in Azure

# Set variables for the container names
$containerName = "azure-toolkit2"
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

try {

    # Remove the temporary container if it exists

    "Trying to remove any temporary containers, created on previous runs of the script..."
    Remove-AzureStorageContainer -Name "$additionalContainerName" -Context $ctx -Force -ErrorAction Stop
    
}
catch {
    
    "...no temporary container found"

}

# Try to write to the container - if failing, use a temporary one
try {

    "Verifying the existence of the current Azure container..."

	# Check if the container name already exists
    Get-AzureStorageContainer -Container $containerName -Context $ctx -ErrorAction Stop

    Get-ChildItem -File -Recurse "C:\_deployment\website_packaged\convert to WDP\WPD\modules" | ForEach-Object { Set-AzureStorageBlobContent -File $_.FullName -Blob $_.FullName.Substring(3) -Container $containerName -Context $ctx -Force}
}
catch {

    try {

        "Trying to create the container..."

        # Create the main container for the WDPs
        New-AzureStorageContainer -Name $containerName -Context $ctx -Permission blob -ErrorAction Stop

        # Upload the WDP modules to the blob container
        Get-ChildItem -File -Recurse "C:\_deployment\website_packaged\convert to WDP\WPD\modules" | ForEach-Object { Set-AzureStorageBlobContent -File $_.FullName -Blob $_.FullName.Substring(3) -Container $containerName -Context $ctx -Force}

    }
    catch {
    
        "It seems like the container has been deleted very recently... creating a temporary container instead"

        # Create a temporary container
        New-AzureStorageContainer -Name $additionalContainerName -Context $ctx -Permission blob

        # Upload the WDP modules to the temporary blob container
        Get-ChildItem -File -Recurse "C:\_deployment\website_packaged\convert to WDP\WPD\modules" | ForEach-Object { Set-AzureStorageBlobContent -File $_.FullName -Blob $_.FullName.Substring(3) -Container $containerName -Context $ctx -Force}
    
    }
    
}

#########################################
# Get the URL for each blob and record it

$WDPlist = Get-AzureStorageBlob -Container $containerName -Context $ctx | ForEach-Object {
    
    if ($_.Name -eq "modules/SXA_single.scwdp.zip"){

        $sxaMsDeployPackageUrl = (Get-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri

    } elseif ($_.Name -eq "modules/SPE_single.scwdp.zip"){
    
        $speMsDeployPackageUrl = (Get-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri
    
    } elseif ($_.Name -eq "modules/1 Data Exchange Framework 2.0.1 rev. 180108_single.scwdp.zip"){
    
        $defDeployPackageUrl = (Get-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri
    
    } elseif ($_.Name -eq "modules/2 Sitecore Provider for Data Exchange Framework 2.0.1 rev. 180108_single.scwdp.zip"){
    
        $defSitecoreDeployPackageUrl = (Get-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri
    
    } elseif ($_.Name -eq "modules/3 SQL Provider for Data Exchange Framework 2.0.1 rev. 180108_single.scwdp.zip"){
    
        $defSqlDeployPackageUrl = (Get-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri
    
    } elseif ($_.Name -eq "modules/4 xConnect Provider for Data Exchange Framework 2.0.1 rev. 180108_single.scwdp.zip"){
    
        $defxConnectDeployPackageUrl = (Get-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri
    
    } elseif ($_.Name -eq "modules/5 Dynamics Provider for Data Exchange Framework 2.0.1 rev. 180108_single.scwdp.zip"){
    
        $defDynamicsDeployPackageUrl = (Get-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri
    
    } elseif ($_.Name -eq "modules/6 Connect for Microsoft Dynamics 2.0.1 rev. 180108_single.scwdp.zip"){
    
        $defDynamicsConnectDeployPackageUrl = (Get-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri
    
    } elseif ($_.Name -eq "modules/Sitecore.Cloud.Integration.Bootload.wdp.zip"){
    
        $msDeployPackageUrl = (Get-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri
    
    }
    
}

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
$azuredeploy_template.parameters | ForEach-Object {

    $_.deploymentId.value = $deployemtId
    $_.location.value = $location
    $_.sitecoreAdminPassword.value = $sitecoreAdminPassword
    $_.licenseXml.value = $licenseXml
    $_.sqlServerLogin.value = $sqlServerLogin
    $_.sqlServerPassword.value = $sqlServerPassword
    $_.authCertificatePassword.value = $authCertificatePassword
    $_.singleMsDeployPackageUrl.value = $singleMsDeployPackageUrl
    $_.xcSingleMsDeployPackageUrl.value = $xcSingleMsDeployPackageUrl
    $_.modules.value.items[0].parameters.sxaMsDeployPackageUrl = $sxaMsDeployPackageUrl
    $_.modules.value.items[0].parameters.speMsDeployPackageUrl = $speMsDeployPackageUrl
    $_.modules.value.items[1].parameters.defDeployPackageUrl = $defDeployPackageUrl
    $_.modules.value.items[1].parameters.defSitecoreDeployPackageUrl = $defSitecoreDeployPackageUrl
    $_.modules.value.items[1].parameters.defSqlDeployPackageUrl = $defSqlDeployPackageUrl
    $_.modules.value.items[1].parameters.defxConnectDeployPackageUrl = $defxConnectDeployPackageUrl
    $_.modules.value.items[1].parameters.defDynamicsDeployPackageUrl = $defDynamicsDeployPackageUrl
    $_.modules.value.items[1].parameters.defDynamicsConnectDeployPackageUrl = $defDynamicsConnectDeployPackageUrl
    $_.modules.value.items[2].parameters.msDeployPackageUrl = $msDeployPackageUrl
    $_.modules.value.items[0].templateLink = $sxaTemplateLink
    $_.modules.value.items[1].templateLink = $defTemplateLink
    $_.modules.value.items[2].templateLink = $bootloaderTemplateLink

}

$azuredeploy_template | ConvertTo-Json -Depth 20 | Set-Content 'C:\Users\auzunov\Downloads\ARM_deploy\!Deployment\Azure PaaS\Sitecore 9.0.2\Xp Single\azuredeploy.parameters - Copy.json'