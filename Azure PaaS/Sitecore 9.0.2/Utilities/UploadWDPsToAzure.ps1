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