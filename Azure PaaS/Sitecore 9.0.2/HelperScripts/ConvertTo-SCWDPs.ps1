### 3rd Party Ionic Zip function, defined here

function Zip ([String] $FolderToZip, [String] $ZipFilePath) {

  # load Ionic.Zip.dll 
  
  [System.Reflection.Assembly]::LoadFrom("C:\Users\auzunov\Downloads\ARM_deploy\1_Sitecore Azure Toolkit\tools\DotNetZip.dll")
  $Encoding = [System.Text.Encoding]::GetEncoding(65001)
  $ZipFile =  New-Object Ionic.Zip.ZipFile($Encoding)

  $ZipFile.AddDirectory($FolderToZip)

  if (!(Test-Path (Split-Path $ZipFilePath -Parent))) {

    mkdir (Split-Path $ZipFilePath -parent)

  }

  Write-Host "Saving zip file from $FolderToZip"
  $ZipFile.Save($ZipFilePath)
  $ZipFile.Dispose()
  Write-Host "Saved..."

}

#########################################################
### Create the WDP for Habitat Home from the build output
#########################################################

### Prepare WDP folders and paths
# Create empty folder structures for the WDP work

[String] $rootFolder = "C:\_deployment\website_packaged_test"
[String] $SourceFolderPath = "$($rootFolder)\SourcePackage"
$DestinationFolderPath = New-Item -Path "$($rootFolder)\convert to WDP\WPD" -ItemType Directory -Force

# WDP Components folder and sub-folders creation

$ComponentsFolderPath = New-Item -Path "$($rootFolder)\convert to WDP\Components" -ItemType Directory -Force
$CargoPayloadFolderPath = New-Item -Path "$($ComponentsFolderPath)\CargoPayloads" -ItemType Directory -Force
$AdditionalWdpContentsFolderPath = New-Item -Path "$($ComponentsFolderPath)\AdditionalFiles" -ItemType Directory -Force
$JsonConfigFolderPath = New-Item -Path "$($ComponentsFolderPath)\Configs" -ItemType Directory -Force
$ParameterXmlFolderPath = New-Item -Path "$($ComponentsFolderPath)\MsDeployXmls" -ItemType Directory -Force

### Provide the required files for WDP

[String] $SitecoreCloudModulePath = "C:\Users\auzunov\Downloads\ARM_deploy\1_Sitecore Azure Toolkit\tools\Sitecore.Cloud.Cmdlets.psm1"
[String] $InitialConfigFilePath = "$($rootFolder)\website_config.json"
[String] $InitialParameterXmlFilePath = "$($rootFolder)\website_parameters.xml"

[String] $ConfigFilePath = "$($JsonConfigFolderPath)\website_config.json"
[String] $CargoPayloadZipFilePath = "$($ComponentsFolderPath)\website_cargo.zip"
[String] $CargoPayloadFilePath = "$($CargoPayloadFolderPath)\website_cargo.sccpl"

# Copy the parameters.xml file over to the target ParameterXml folder

Copy-Item -Path $InitialParameterXmlFilePath -Destination $ParameterXmlFolderPath.FullName -Force

# Copy the config.json file over to the target Config folder

Copy-Item -Path $InitialConfigFilePath -Destination $ConfigFilePath -Force

# Create folders for Sitecore Cargo Payload file

$CopyToRootPath = New-Item -Path "$($CargoPayloadFolderPath)\CopyToRoot" -ItemType Directory -Force
$CopyToWebsitePath = New-Item -Path "$($CargoPayloadFolderPath)\CopyToWebsite" -ItemType Directory -Force
$IOActionsPath = New-Item -Path "$($CargoPayloadFolderPath)\IOActions" -ItemType Directory -Force
$XdtsPath = New-Item -Path "$($CargoPayloadFolderPath)\Xdts" -ItemType Directory -Force

# Zip up all Cargo Payload folders using Ionic Zip

Zip -FolderToZip $CargoPayloadFolderPath.FullName -ZipFilePath $CargoPayloadZipFilePath

# Move and rename the zipped file to .sccpl - create the Sitecore Cargo Payload file

Move-Item -Path $CargoPayloadZipFilePath -Destination $CargoPayloadFilePath -Force

# Clean up SCCPL folders

Remove-Item -Path $CopyToRootPath.FullName -Recurse -Force
Remove-Item -Path $CopyToWebsitePath.FullName -Recurse -Force
Remove-Item -Path $IOActionsPath.FullName -Recurse -Force
Remove-Item -Path $XdtsPath.FullName -Recurse -Force
Remove-Item -Path $CargoPayloadZipFilePath -ErrorAction Ignore

### Build the WDP file

Import-Module $SitecoreCloudModulePath -Verbose
Start-SitecoreAzureModulePackaging -SourceFolderPath $SourceFolderPath `
                                    -DestinationFolderPath $DestinationFolderPath.FullName `
                                    -CargoPayloadFolderPath $CargoPayloadFolderPath.FullName `
                                    -AdditionalWdpContentsFolderPath $AdditionalWdpContentsFolderPath.FullName `
                                    -ParameterXmlFolderPath $ParameterXmlFolderPath.FullName `
                                    -ConfigFilePath $ConfigFilePath `
                                    -Verbose

########################################################################
### Create the WDP for the Data Exchange Framework module and components
########################################################################

# Initial check to see if the WDP package was already present and skip creation

if (!$WdpPackagePresent){

    $SitecoreCloudModulePath = "C:\Users\auzunov\Downloads\ARM_deploy\1_Sitecore Azure Toolkit\tools\Sitecore.Cloud.Cmdlets.psm1"
    $SourceFolderPath = "C:\_deployment\website_packaged"
    $DestinationFolderPath = "C:\_deployment\website_packaged\convert to WDP\WPD"
    $CargoPayloadFolderPath = "C:\_deployment\website_packaged\convert to WDP\Components\CargoPayloads"
    $AdditionalWdpContentsFolderPath = "C:\_deployment\website_packaged\convert to WDP\Components\AdditionalFiles"
    $ParameterXmlFolderPath = "C:\_deployment\website_packaged\convert to WDP\Components\MsDeployXmls"
    $ConfigFilePath = "C:\_deployment\website_packaged\convert to WDP\Components\Configs\website_config.json"

    Import-Module $SitecoreCloudModulePath -Verbose
    Start-SitecoreAzureModulePackaging -SourceFolderPath $SourceFolderPath `
                                       -DestinationFolderPath $DestinationFolderPath `
                                       -CargoPayloadFolderPath $CargoPayloadFolderPath `
                                       -AdditionalWdpContentsFolderPath $AdditionalWdpContentsFolderPath `
                                       -ParameterXmlFolderPath $ParameterXmlFolderPath `
                                       -ConfigFilePath $ConfigFilePath `
                                       -Verbose

}