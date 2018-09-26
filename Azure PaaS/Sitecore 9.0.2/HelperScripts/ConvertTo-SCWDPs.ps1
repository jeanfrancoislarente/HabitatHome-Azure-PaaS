######################################################################
# Create the WDP for the Data Exchange Framework module and components

# Initial check to see if the WDP package was already present and skip creation

if (!$WdpPackagePresent){

# Prepare WDP folders and paths

$SourceFolderPath = New-Item -Path "C:\_deployment\website_packaged_test" -ItemType directory -Force
$DestinationFolderPath = New-Item -Path "C:\_deployment\website_packaged_test\convert to WDP\WPD" -ItemType directory -Force
$CargoPayloadFolderPath = New-Item -Path "C:\_deployment\website_packaged_test\convert to WDP\Components\CargoPayloads" -ItemType directory -Force
$AdditionalWdpContentsFolderPath = New-Item -Path "C:\_deployment\website_packaged_test\convert to WDP\Components\AdditionalFiles" -ItemType directory -Force
$ParameterXmlFolderPath = New-Item -Path "C:\_deployment\website_packaged_test\convert to WDP\Components\MsDeployXmls" -ItemType directory -Force
$SitecoreCloudModulePath = "C:\Users\auzunov\Downloads\ARM_deploy\1_Sitecore Azure Toolkit\tools\Sitecore.Cloud.Cmdlets.psm1"
$ConfigFilePath = "C:\_deployment\website_packaged\convert to WDP\Components\Configs\website.config.json"
$ParameterXmlFilePath = "C:\_deployment\website_packaged\convert to WDP\Components\MsDeployXmls\website_parameters.xml"

# Copy the parameters.xml file over to the $ParameterXmlFolderPath.FullName folder

Copy-Item -Path $ParameterXmlFilePath -Destination $ParameterXmlFolderPath.FullName -Force

# Create the Sitecore Cargo Payload file

# Create folders for Sitecore Cargo Payload file

$CopyToRootPath = New-Item -Path "C:\_deployment\website_packaged_test\convert to WDP\Components\CargoPayloads\CopyToRoot" -ItemType directory -Force
$CopyToWebsitePath = New-Item -Path "C:\_deployment\website_packaged_test\convert to WDP\Components\CargoPayloads\CopyToWebsite" -ItemType directory -Force
$IOActionsPath = New-Item -Path "C:\_deployment\website_packaged_test\convert to WDP\Components\CargoPayloads\IOActions" -ItemType directory -Force
$XdtsPath = New-Item -Path "C:\_deployment\website_packaged_test\convert to WDP\Components\CargoPayloads\Xdts" -ItemType directory -Force

# Zip up all folders in a single zip file (NOT working yet because it creates a zip that includes the root folder - I don't want that)

Compress-Archive -Path $CargoPayloadFolderPath.FullName -DestinationPath "$($CargoPayloadFolderPath.FullName)\website_cargo" -Force

# Rename the zipped file extension to .sccpl

Rename-Item -Path "$($CargoPayloadFolderPath.FullName)\website_cargo.zip" -NewName "website_cargo.sccpl"

# Clean up SCCPL folders

Remove-Item -Path $CopyToRootPath.FullName
Remove-Item -Path $CopyToWebsitePath.FullName
Remove-Item -Path $IOActionsPath.FullName
Remove-Item -Path $XdtsPath.FullName

# Build the WDP module

Import-Module $SitecoreCloudModulePath -Verbose
Start-SitecoreAzureModulePackaging -SourceFolderPath $SourceFolderPath.FullName `
                                   -DestinationFolderPath $DestinationFolderPath.FullName `
                                   -CargoPayloadFolderPath $CargoPayloadFolderPath.FullName `
                                   -AdditionalWdpContentsFolderPath $AdditionalWdpContentsFolderPath.FullName `
                                   -ParameterXmlFolderPath $ParameterXmlFolderPath.FullName `
                                   -ConfigFilePath $ConfigFilePath `
                                   -Verbose

}

# Create the WDP for Habitat Home from the build output (not started working on this yet...)

$SitecoreCloudModulePath = "C:\Users\auzunov\Downloads\ARM_deploy\1_Sitecore Azure Toolkit\tools\Sitecore.Cloud.Cmdlets.psm1"
$SourceFolderPath = "C:\_deployment\website_packaged"
$DestinationFolderPath = "C:\_deployment\website_packaged\convert to WDP\WPD"
$CargoPayloadFolderPath = "C:\_deployment\website_packaged\convert to WDP\Components\CargoPayloads"
$AdditionalWdpContentsFolderPath = "C:\_deployment\website_packaged\convert to WDP\Components\AdditionalFiles"
$ParameterXmlFolderPath = "C:\_deployment\website_packaged\convert to WDP\Components\MsDeployXmls"
$ConfigFilePath = "C:\_deployment\website_packaged\convert to WDP\Components\Configs\website.config.json"

Import-Module $SitecoreCloudModulePath -Verbose
Start-SitecoreAzureModulePackaging -SourceFolderPath $SourceFolderPath `
                                   -DestinationFolderPath $DestinationFolderPath `
                                   -CargoPayloadFolderPath $CargoPayloadFolderPath `
                                   -AdditionalWdpContentsFolderPath $AdditionalWdpContentsFolderPath `
                                   -ParameterXmlFolderPath $ParameterXmlFolderPath `
                                   -ConfigFilePath $ConfigFilePath `
                                   -Verbose