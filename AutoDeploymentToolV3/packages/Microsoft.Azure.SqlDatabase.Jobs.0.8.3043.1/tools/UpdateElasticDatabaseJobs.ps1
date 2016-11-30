######################################################################################
### Update Elastic Database Jobs Script
###
### This script updates the Elastic Database Jobs service binaries within an existing
### installation in the current Azure subscription.
###
### Parameters:
### $ResourceGroupName:  Specifies the resource group for the existing installation.
###                      It is recommended to use the default setting of __ElasticDatabaseJob
###                      since Azure Portal uses this resource group name to identify
###                      Elastic Database Job installations.
### $ServiceVmSize:      Modifies the service VM size.  A0/A1/A2/A3 are acceptable
###                      parameter values.
### $ServiceWorkerCount: The worker count to be used across the Azure Cloud Service.
###                      If not specified, the current worker count configuration
###                      will continue to be used.
######################################################################################


param (
    $ResourceGroupName = "__ElasticDatabaseJob",
    $CsmTemplateUri = "http://elasticscale.blob.core.windows.net/edj-150727-release/ElasticDatabaseJobServiceUpdateCsmTemplate.json?sv=2014-02-14&sr=c&sig=ujdgGAE55kY9%2BKWWCR%2BuLyhX2nKaf8jlloL1Wsnxyc0%3D&st=2015-07-27T07%3A00%3A00Z&se=2099-08-04T07%3A00%3A00Z&sp=r",
    $ServiceDeploymentLabel = $null,
    $ServiceVmSize = "A0",
    $ServiceWorkerCount = $null,
    [switch]$NoPrompt
)

######################################################################################
### Helper functions
######################################################################################

function Log([Parameter(ValueFromPipeline=$true)]$Message, $LogColor = "Cyan")
{
    Write-Host $Message -ForegroundColor $LogColor
}

function GetAzureServiceName()
{
    param (
        [Parameter(Mandatory=$true)][string]$ResourceGroupName
    )

    # Try to determine the service name used within the resource group already.
    $azureResources =  Get-AzureResource -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if(!$azureResources)
    {
        throw "Could not find the resource group $ResourceGroupName"
    }

    $ServiceName = $null
    Foreach($azureResource in $azureResources)
    {
        if($azureResource.Name.Contains("/"))
        {
            # Ignore resource names created by compounding parents
            continue;
        }

        if($ServiceName -and !$azureResource.Name.Equals($ServiceName))
        {
            throw ("There were multiple different service names found in the subscription, supply the desired one using the -ServiceName parameter.  Service names: $ServiceName " + $azureResource.Name)
        }
        $ServiceName = $azureResource.Name
    }

    if(!$ServiceName)
    {
        throw "Could not identify any Azure resources within the resource group $ResourceGroupName"
    }

    return $ServiceName
}

function GetServiceDeployment()
{
    return Get-AzureResource `
            -ResourceGroupName $ResourceGroupName `
            -ApiVersion $ServiceApiVersion `
            -ParentResource $ServiceResourceName `
            -ResourceType $ServiceDeploymentResourceType `
            -ResourceName $ServiceDeploymentName
}

######################################################################################
### Script starts here
######################################################################################

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Switch-AzureMode AzureResourceManager

# Check that Azure Powershell is installed
if ($(Get-Module AzureResourceManager -ListAvailable) -eq $null)
{
    throw "AzureResourceManager PowerShell module is not installed. See http://azure.microsoft.com/en-us/documentation/articles/install-configure-powershell/"
}

# See if subscriptions have been initialized
Log "Looking up subscriptions"
if ($(Get-AzureSubscription | Measure-Object).Count -eq 0)
{
    Write-Host "Getting your subscriptions..."
    Add-AzureAccount
}

$importantSettingsColor = "Yellow"
$otherSettingsColor = "Gray"
$helpColor = "Gray"
$logColor = "Cyan"

# Get the current subscription
$subscription = Get-AzureSubscription -Current

# Get the resource group and its location
Log "Looking up the resource group: $ResourceGroupName..."
$ResourceGroup = Get-AzureResourceGroup -Name $ResourceGroupName
$ResourceGroup

# Use the resource group's location since the Azure Service's location is empty.  Should be the same.
$ServiceLocation = $ResourceGroup.Location

# Determine the service name
Log "Looking up the service name..."
$ServiceName = GetAzureServiceName -ResourceGroupName $ResourceGroupName
$ServiceName

$ServiceApiVersion = "2014-06-01"
$ServiceResourceName = "Microsoft.ClassicCompute/domainNames/$ServiceName"
$ServiceDeploymentResourceType = "/slots"
$ServiceDeploymentName = "production"

# Build the production deployment name
if(!$ServiceDeploymentLabel)
{
    $ServiceDeploymentLabelGuid = [Guid]::NewGuid()
    $ServiceDeploymentLabel = ("EdjUpdate_$ServiceDeploymentLabelGuid").ToLowerInvariant().Replace("-", "")
}

# Look up the production deployment
Log "Looking up the service deployment..."
$serviceDeployment = GetServiceDeployment
$serviceDeployment

if($serviceDeployment.Properties.Get_Item("deploymentLabel").Equals($ServiceDeploymentLabel))
{
    Log "Update deployment already in place"
    return
}

$serviceDeploymentConfiguration = $serviceDeployment.Properties.Get_Item("configuration")
$serviceConfigurationXml = New-Object System.Xml.XmlDocument
$serviceConfigurationXml.LoadXml($serviceDeploymentConfiguration)

# Manipulate the service configuration for the service worker count, if specified
if($ServiceWorkerCount)
{
    $intServiceWorkerCount = [Int32]::Parse($ServiceWorkerCount)
    if($intServiceWorkerCount -le 0 -or $intServiceWorkerCount -gt 10)
    {
        throw "ServiceWorkerCount specification must be between 1-9: $ServiceWorkerCount"
    }

    $instancesXmlElement = [System.Xml.XmlElement]$serviceConfigurationXml.SelectSingleNode("/*[name()='ServiceConfiguration']/*[name()='Role']/*[name()='Instances']")
    $instancesXmlElement.SetAttribute("count", $intServiceWorkerCount.ToString())
}
$serviceDeploymentConfiguration = $serviceConfigurationXml.OuterXml

# Determine the service binary location
$serviceBinaryLocations = @{ 	
    "A0" = "http://elasticscale.blob.core.windows.net/edj-150727-release/ElasticDatabaseJobService.cspkg?sv=2014-02-14&sr=c&sig=ujdgGAE55kY9%2BKWWCR%2BuLyhX2nKaf8jlloL1Wsnxyc0%3D&st=2015-07-27T07%3A00%3A00Z&se=2099-08-04T07%3A00%3A00Z&sp=r";
    "A1" = "http://elasticscale.blob.core.windows.net/edj-150727-release/ElasticDatabaseJobService_Small.cspkg?sv=2014-02-14&sr=c&sig=ujdgGAE55kY9%2BKWWCR%2BuLyhX2nKaf8jlloL1Wsnxyc0%3D&st=2015-07-27T07%3A00%3A00Z&se=2099-08-04T07%3A00%3A00Z&sp=r";
    "A2" = "http://elasticscale.blob.core.windows.net/edj-150727-release/ElasticDatabaseJobService_Medium.cspkg?sv=2014-02-14&sr=c&sig=ujdgGAE55kY9%2BKWWCR%2BuLyhX2nKaf8jlloL1Wsnxyc0%3D&st=2015-07-27T07%3A00%3A00Z&se=2099-08-04T07%3A00%3A00Z&sp=r";
    "A3" = "http://elasticscale.blob.core.windows.net/edj-150727-release/ElasticDatabaseJobService_Large.cspkg?sv=2014-02-14&sr=c&sig=ujdgGAE55kY9%2BKWWCR%2BuLyhX2nKaf8jlloL1Wsnxyc0%3D&st=2015-07-27T07%3A00%3A00Z&se=2099-08-04T07%3A00%3A00Z&sp=r";
}

# Determine the service binary location
$serviceBinaryLocation = $serviceBinaryLocations.Get_Item($ServiceVmSize)
if(!$serviceBinaryLocation)
{
    throw "Invalid service binary vm size: $ServiceVmSize"
}

$CsmTemplateParameters = @{ 	
        "SERVICE_NAME"               = $ServiceName;
        "SERVICE_PACKAGELINK"        = $serviceBinaryLocation;
        "SERVICE_LOCATION"           = $ServiceLocation;
        "SERVICE_DEPLOYMENT_LABEL"   = $ServiceDeploymentLabel;
        "SERVICE_CSCFG"              = $serviceDeploymentConfiguration;
}

Log 
Log "Using the following settings to launch the Elastic Database Job service binary update:"
Log
Log "Resource Group Name:      $ResourceGroupName"
Log "Service Name:             $ServiceName"
Log "Service Deployment Label: $ServiceDeploymentLabel"
Log "Service VM Size:          $ServiceVmSize"
Log "CSM Template Uri:         $CsmTemplateUri"
Log "Service Configuration:    $serviceDeploymentConfiguration"
Log

if (-not $NoPrompt)
{
    Write-Host "If these settings are ok, press enter. To quit, press Control-C." -ForegroundColor Yellow
    Read-Host
}

Log "Ensure that the Cloud Services Azure provider is registered"
Log
Register-AzureProvider -ProviderNamespace "Microsoft.ClassicCompute" -Force

Log "Deploying new service binary..."
Log
New-AzureResourceGroupDeployment `
            -ResourceGroupName $ResourceGroupName `
            -Name $ServiceDeploymentLabel `
            -TemplateUri $CsmTemplateUri `
            -TemplateParameterObject $CsmTemplateParameters
            
Log
Log "Update has completed successfully."
Log