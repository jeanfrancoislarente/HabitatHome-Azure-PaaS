#addin "Cake.XdtTransform"
#addin "Cake.Powershell"
#addin "Cake.Http"
#addin "Cake.Json"
#addin "Newtonsoft.Json"


#load "local:?path=CakeScripts/helper-methods.cake"


var target = Argument<string>("Target", "Default");
var configuration = new Configuration();
var cakeConsole = new CakeConsole();
var configJsonFile = "cake-config.json";
//var unicornSyncScript = $"./scripts/Unicorn/Sync.ps1";

/*===============================================
================ MAIN TASKS =====================
===============================================*/

Setup(context =>
{
	cakeConsole.ForegroundColor = ConsoleColor.Yellow;
	PrintHeader(ConsoleColor.DarkGreen);
	
    var configFile = new FilePath(configJsonFile);
    configuration = DeserializeJsonFromFile<Configuration>(configFile);
});

var HabitatHomeSiteDeployFolder = $"{configuration.DeployFolder}\\Website\\HabitatHome"

Task("Default")
.WithCriteria(configuration != null)
.IsDependentOn("Clean")
.IsDependentOn("Publish-All-Projects")
.IsDependentOn("Apply-Xml-Transform")
//.IsDependentOn("Modify-Unicorn-Source-Folder")
//.IsDependentOn("Sync-Unicorn")
.IsDependentOn("Publish-Transforms")
.IsDependentOn("Publish-xConnect-Project");
//.IsDependentOn("Deploy-EXM-Campaigns")
//.IsDependentOn("Deploy-Marketing-Definitions")
//.IsDependentOn("Rebuild-Core-Index")
//.IsDependentOn("Rebuild-Master-Index")
//.IsDependentOn("Rebuild-Web-Index");
.IsDependentOn("Publish-YML");
.IsDependentOn("Azure-Build");
.IsDependentOn("Azure-Deploy");

//Task("Quick-Deploy")
//.WithCriteria(configuration != null)
//.IsDependentOn("Clean")
//.IsDependentOn("Publish-All-Projects")
//.IsDependentOn("Apply-Xml-Transform")
//.IsDependentOn("Publish-Transforms")
//.IsDependentOn("Publish-xConnect-Project");

/*===============================================
================= SUB TASKS =====================
===============================================*/

Task("Clean").Does(() => {
    CleanDirectories($"{configuration.SourceFolder}/**/obj");
    CleanDirectories($"{configuration.SourceFolder}/**/bin");
});

Task("Publish-All-Projects")
.IsDependentOn("Build-Solution")
.IsDependentOn("Publish-Foundation-Projects")
.IsDependentOn("Publish-Feature-Projects")
.IsDependentOn("Publish-Project-Projects");


Task("Build-Solution").Does(() => {
    MSBuild(configuration.SolutionFile, cfg => InitializeMSBuildSettings(cfg));
});

Task("Publish-Foundation-Projects").Does(() => {
    PublishProjects(configuration.FoundationSrcFolder, HabitatHomeSiteDeployFolder);
});

Task("Publish-Feature-Projects").Does(() => {
    PublishProjects(configuration.FeatureSrcFolder, HabitatHomeSiteDeployFolder);
});

Task("Publish-Project-Projects").Does(() => {
    var common = $"{configuration.ProjectSrcFolder}\\Common";
    var habitat = $"{configuration.ProjectSrcFolder}\\Habitat";
    var habitatHome = $"{configuration.ProjectSrcFolder}\\HabitatHome";

    PublishProjects(common, HabitatHomeSiteDeployFolder);
    PublishProjects(habitat, HabitatHomeSiteDeployFolder);
    PublishProjects(habitatHome, HabitatHomeSiteDeployFolder);
});

Task("Publish-xConnect-Project").Does(() => {
    var xConnectProject = $"{configuration.ProjectSrcFolder}\\xConnect";
	var xConnectDeployFolder = $"{configuration.DeployFolder}\\Website\\xConnect";
	
    PublishProjects(xConnectProject, xConnectDeployFolder);
});

Task("Apply-Xml-Transform").Does(() => {
    var layers = new string[] { configuration.FoundationSrcFolder, configuration.FeatureSrcFolder, configuration.ProjectSrcFolder};

    foreach(var layer in layers)
    {
        Transform(layer);
    }
});

Task("Publish-Transforms").Does(() => {
    var layers = new string[] { configuration.FoundationSrcFolder, configuration.FeatureSrcFolder, configuration.ProjectSrcFolder};
    var destination = $@"{HabitatHomeSiteDeployFolder}\temp\transforms";

    CreateFolder(destination);

    try
    {
        var files = new List<string>();
        foreach(var layer in layers)
        {
            var xdtFiles = GetTransformFiles(layer).Select(x => x.FullPath).ToList();
            files.AddRange(xdtFiles);
        }   

        CopyFiles(files, destination, preserveFolderStructure: true);
    }
    catch (System.Exception ex)
    {
        WriteError(ex.Message);
    }
});

//Task("Modify-Unicorn-Source-Folder").Does(() => {
//    var zzzDevSettingsFile = File($"{HabitatHomeSiteDeployFolder}/App_config/Include/Project/z.Common.Website.DevSettings.config");
//    
//	var rootXPath = "configuration/sitecore/sc.variable[@name='{0}']/@value";
//    var sourceFolderXPath = string.Format(rootXPath, "sourceFolder");
//    var directoryPath = MakeAbsolute(new DirectoryPath(configuration.SourceFolder)).FullPath;
//
//    var xmlSetting = new XmlPokeSettings {
//        Namespaces = new Dictionary<string, string> {
//            {"patch", @"http://www.sitecore.net/xmlconfig/"}
//        }
//    };
//    XmlPoke(zzzDevSettingsFile, sourceFolderXPath, directoryPath, xmlSetting);
//});

//Task("Sync-Unicorn").Does(() => {
//    var unicornUrl = configuration.InstanceUrl + "unicorn.aspx";
//    Information("Sync Unicorn items from url: " + unicornUrl);
//
//   var authenticationFile = new FilePath($"{HabitatHomeSiteDeployFolder}/App_config/Include/Unicorn.SharedSecret.config");
//    var xPath = "/configuration/sitecore/unicorn/authenticationProvider/SharedSecret";
//
//    string sharedSecret = XmlPeek(authenticationFile, xPath);
//
//    
//    StartPowershellFile(unicornSyncScript, new PowershellSettings()
//                                                        .SetFormatOutput()
//                                                        .SetLogOutput()
//                                                        .WithArguments(args => {
//                                                            args.Append("secret", sharedSecret)
//                                                                .Append("url", unicornUrl);
//                                                        }));
//});

Task("Deploy-EXM-Campaigns").Does(() => {
    var url = $"{configuration.InstanceUrl}utilities/deployemailcampaigns.aspx?apiKey={configuration.MessageStatisticsApiKey}";
    string responseBody = HttpGet(url);

    Information(responseBody);
});

Task("Deploy-Marketing-Definitions").Does(() => {
    var url = $"{configuration.InstanceUrl}utilities/deploymarketingdefinitions.aspx?apiKey={configuration.MarketingDefinitionsApiKey}";
    string responseBody = HttpGet(url);

    Information(responseBody);
});

Task("Rebuild-Core-Index").Does(() => {
    RebuildIndex("sitecore_core_index");
});

Task("Rebuild-Master-Index").Does(() => {
    RebuildIndex("sitecore_master_index");
});

Task("Rebuild-Web-Index").Does(() => {
    RebuildIndex("sitecore_web_index");
});

Task("Publish-YML").Does(() => {
	StartPowershellFile ($"{configuration.projectFolder}\Azure PaaS\Sitecore 9.0.2\Utilities\Publish-YML.ps1");
});

Task("Azure-Build")
.IsDependentOn("Download-Prerequisites")
.IsDependentOn("ConvertTo-SCWDPs")
.IsDependentOn("Upload-Packages");

Task("Download-Prerequisites").Does(() => {

	var dlCheckResults = StartPowershellFile ($"{configuration.projectFolder}\Azure PaaS\Sitecore 9.0.2\Utilities\Download-Prerequisites.ps1"args =>
        {
            args.Append(local:?path);
        }););

Task("ConvertTo-SCWDPs").Does(() => {
	StartPowershellFile ($"{configuration.projectFolder}\Azure PaaS\Sitecore 9.0.2\Utilities\ConvertTo-SCWDPs.ps1", args =>
        {
            args.Append(dlCheckResults);
        }););
});

Task("Upload-Packages").Does(() => {
	StartPowershellFile ($"{configuration.projectFolder}\Azure PaaS\Sitecore 9.0.2\Utilities\Upload-Packages.ps1");
});

Task("Azure-Deploy").Does(() => {
	StartPowershellFile ($"{configuration.projectFolder}\Azure PaaS\Sitecore 9.0.2\Utilities\Azure-Deploy.ps1");
});

RunTarget(target);