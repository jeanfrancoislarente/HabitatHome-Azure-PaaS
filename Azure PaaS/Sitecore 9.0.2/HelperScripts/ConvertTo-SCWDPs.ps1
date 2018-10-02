#################################################################
# 3rd Party Ionic Zip function - helping create the SCCPL package

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

###############################
# Create the Web Deploy Package

function Create-WDP ([String] $RootFolder, [String] $SitecoreCloudModulePath, [String] $JsonConfigFilename, [String] $XmlParameterFilename, [String] $SccplCargoFilename, [bool] $WdpPackagePresent){

    # Initial check to see if the WDP package was already present and skip creation

    if (!$WdpPackagePresent){

        # Create empty folder structures for the WDP work

        [String] $SourceFolderPath = "$($RootFolder)\SourcePackage"
        $DestinationFolderPath = New-Item -Path "$($RootFolder)\convert to WDP\WPD" -ItemType Directory -Force

        # WDP Components folder and sub-folders creation

        $ComponentsFolderPath = New-Item -Path "$($RootFolder)\convert to WDP\Components" -ItemType Directory -Force
        $CargoPayloadFolderPath = New-Item -Path "$($ComponentsFolderPath)\CargoPayloads" -ItemType Directory -Force
        $AdditionalWdpContentsFolderPath = New-Item -Path "$($ComponentsFolderPath)\AdditionalFiles" -ItemType Directory -Force
        $JsonConfigFolderPath = New-Item -Path "$($ComponentsFolderPath)\Configs" -ItemType Directory -Force
        $ParameterXmlFolderPath = New-Item -Path "$($ComponentsFolderPath)\MsDeployXmls" -ItemType Directory -Force

        ### Provide the required files for WDP

        [String] $InitialConfigFilePath = "$($RootFolder)\$($JsonConfigFilename).json"
        [String] $InitialParameterXmlFilePath = "$($RootFolder)\$($XmlParameterFilename).xml"

        [String] $ConfigFilePath = "$($JsonConfigFolderPath)\$($JsonConfigFilename).json"
        [String] $CargoPayloadZipFilePath = "$($ComponentsFolderPath)\$($SccplCargoFilename).zip"
        [String] $CargoPayloadFilePath = "$($CargoPayloadFolderPath)\$($SccplCargoFilename).sccpl"

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

       }

}


#### Create-WDP function explained:

<#

 -RootFolder is the physical path on the filesystem to the source folder for WDP operations that will contain the WDP JSON configuration file, 
 the WDP XML parameters file and the folder with the module packages
 The typical structure that should be followed is:

    \RootFolder\module_name_module.json
    \RootFolder\module_name_parameters.xml
    \RootFolder\SourcePackage\module_installation_package.zip( or .update)

 -SitecoreCloudModulePath provides the path to the Sitecore.Cloud.Cmdlets.psm1 Azure Toolkit Powershell module (usually under \SAT\tools)

 -JsonConfigFilename is the name of your WDP JSON configuration file

 -XmlParameterFilename is the name of your XML parameter file (must match the name that is provided inside the JSON config)

 -SccplCargoFilename is the name of your Sitecore Cargo Payload package (must match the name that is provided inside the JSON config)

 -WdpPackagePresent is a boolean that skips WDP creation in case the WDP package already exists


 Examples:

 Create-WDP -RootFolder "C:\_deployment\website_packaged_test" `
            -SitecoreCloudModulePath "C:\Users\auzunov\Downloads\ARM_deploy\1_Sitecore Azure Toolkit\tools\Sitecore.Cloud.Cmdlets.psm1" `
            -JsonConfigFilename "website_config" `
            -XmlParameterFilename "website_parameters" `
            -SccplCargoFilename "website_cargo" `
            -WdpPackagePresent $False

 Create-WDP -RootFolder "C:\Users\auzunov\Downloads\ARM_deploy\Modules\DEF" `
            -SitecoreCloudModulePath "C:\Users\auzunov\Downloads\ARM_deploy\1_Sitecore Azure Toolkit\tools\Sitecore.Cloud.Cmdlets.psm1" `
            -JsonConfigFilename "def_config" `
            -XmlParameterFilename "def_parameters" `
            -SccplCargoFilename "def_cargo" `
            -WdpPackagePresent $False

#>