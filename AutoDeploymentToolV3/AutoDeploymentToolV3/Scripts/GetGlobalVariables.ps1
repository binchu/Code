# global variables

$global:deleteRG = $false

# app & sub
$global:appName = $null 
$global:environment = $null
$global:subscriptionDataFile = $null
$global:selectedsubscription = $null

# azure storage
$global:storageAccountName = $null
$global:storageAccountLocation = $null
$global:containerName = $null
$global:zipToUpload = $null

# sql azure
$global:sqlServerName = $null
$global:geoFlag = $null

$global:sqlDatabaseName = $null
$global:sqlPortNumber = $null
$global:sqlUserName = $null
$global:sqlPassword = $null
$global:dacpacFile = $null

# resource group
$global:ResourceGroupName = $null
$global:ServicePlanName = $null
$global:ResourceGroupLocation = $null

$global:BasicResourceGroupName = $null
$global:BasicServicePlanName = $null
$global:BasicResourceGroupLocation = $null

$global:CurrentServicePlanName = $null

# logic app
$global:entitynodes = $null
$global:BasicLAFalg = $null
$global:BasicSqlConnectorName = $null
$global:BasicLogicAppName = $null

$global:user = $null
$global:password = $null
$global:CRMVersion = $null
$global:clientId = $null
$global:crmResourceURL = $null

# Current - inner
$global:currentMicrosoftAccountEnabled = $null
$global:currentEntityName = $null
$global:currentCrmSecondPrimaryKey = $null
$global:currentMAP = $null

$global:currentlogicAppName = $null
$global:currentGatewayName = $null
$global:currentGatewayToApiAppSecret = $null
$global:currentCrmConnectorApiAppNameSite = $null
$global:currentHttpListenerApiAppNameSite = $null
$global:currentHttpListenerApiAppName = $null

# Current - outter & basic
$global:currentSqlConnectorName = $null
$global:currentSqlConnectorSiteName = $null
$global:currentEntityDBPK = $null
$global:currentEntityDBGuidColumnName = $null

# db primary key  - db name
$global:dbpkndict = @{};
$global:dbpkndict.Add("personnelnumber", "Contact");
$global:dbpkndict.Add("accountcode", "Account");
$global:dbpkndict.Add("internalordernbr", "IO");

function GetGlobalVariables {    
    # fetch global variables from user config file
    $configurationFilePath = "$PWD\ConfigurationSettings\UserConfig.xml"
    $config =  [xml](Get-Content $configurationFilePath)

    $nodeAppSelected = $config.Config.AppSelected.Setting | where {$_.name -eq "App"}
    $global:appName = $nodeAppSelected.value

    $nodeEnvSelected = $config.Config.AppSelected.Setting | where {$_.name -eq "Env"}
    $global:environment= $nodeEnvSelected.value

    $nodeSelected = $config.Config.AppSettings | where {$_.name -eq $global:appName}
    $envSelected = $global:environment

    $nodeSqlServerName = $nodeSelected.$envSelected.Setting | where {$_.name -eq "SqlServerName"} 
    $global:sqlServerName = $nodeSqlServerName.value

    $nodeGeoFlag = $nodeSelected.$envSelected.Setting | where {$_.name -eq "GeoFlag"} 
    $global:geoFlag = $nodeGeoFlag.value

    ##
    $nodeUser = $nodeSelected.$envSelected.Setting | where {$_.name -eq "User"} 
    $global:user = $nodeUser.value

    $nodePassword = $nodeSelected.$envSelected.Setting | where {$_.name -eq "Password"} 
    $global:password = $nodePassword.value

    $nodeZipToUpload = $nodeSelected.$envSelected.Setting | where {$_.name -eq "ZipFile"} 
    $global:zipToUpload = $nodeZipToUpload.value

    $nodeCrmResourceURL = $nodeSelected.$envSelected.Setting | where {$_.name -eq "CrmResourceURL"} 
    $global:crmResourceURL = $nodeCrmResourceURL.value

    $nodeClientId = $nodeSelected.$envSelected.Setting | where {$_.name -eq "ClientId"} 
    $global:clientId = $nodeClientId.value
  
    $nodeCRMVersion = $nodeSelected.$envSelected.Setting | where {$_.name -eq "CRMVersion"} 
    $global:CRMVersion = $nodeCRMVersion.value
  

    # fetch entity nodes
    $global:entitynodes = $nodeSelected.LogicApp.Entity

    # fetch global variables from system config file
    $configurationFilePath = "$PWD\ConfigurationSettings\SysConfig.xml"
    $config =  [xml](Get-Content $configurationFilePath)

    $nodeSubscriptionDataFile = $config.Config.PublishSettings
    $global:subscriptionDataFile = "$PWD\ConfigurationSettings\"+ $nodeSubscriptionDataFile

    $nodeSelectedEnvironment = $config.Config.Subscription.Environment | where {$_.name -eq $global:environment}
    $nodeSelectedsubscription = $nodeSelectedEnvironment.Setting | where {$_.name -eq "SelectedSubscription"}
    $global:selectedsubscription = $nodeSelectedsubscription.value


    $nodeSqlDatabase = $config.Config.DBSettings.Setting | where {$_.name -eq 'SqlDatabase'}
    $global:sqlDatabaseName = $nodeSqlDatabase.value

    $nodeSqlPortNumber = $config.Config.DBSettings.Setting | where {$_.name -eq 'SqlPortNumber'}
    $global:sqlPortNumber = $nodeSqlPortNumber.value

    $nodeSqlUserName = $config.Config.DBSettings.Setting | where {$_.name -eq 'SqlUserName'}
    $global:sqlUserName = $nodeSqlUserName.value

    $nodeSqlPassword = $config.Config.DBSettings.Setting | where {$_.name -eq 'SqlPassword'}
    $global:sqlPassword = $nodeSqlPassword.value

    $nodeDacpacFile = $config.Config.DBSettings.Setting | where {$_.name -eq 'DacpacFile'}
    $global:dacpacFile = $nodeDacpacFile.value

    $nodeStorageLocation = $config.Config.StorageSettings.Setting | where {$_.name -eq 'Location'}
    $global:storageAccountLocation = $nodeStorageLocation.value;

    $nodeContainerName = $config.Config.StorageSettings.Setting | where {$_.name -eq 'ContainerName'}
    $global:containerName = $nodeContainerName.value;


    $global:ResourceGroupLocation = $config.Config.ResourceGroupSettings.Entity.Location

    $global:BasicResourceGroupName = $config.Config.ResourceGroupSettings.Basic.BasicResourceGroupName
    $global:BasicServicePlanName = $config.Config.ResourceGroupSettings.Basic.BasicServicePlanName
    $global:BasicResourceGroupLocation = $config.Config.ResourceGroupSettings.Basic.BasicLocation
    $global:BasicLAFalg = $config.Config.ResourceGroupSettings.Basic.BasicLAFalg
    $global:BasicSqlConnectorName = ($config.Config.ResourceGroupSettings.Basic.BasicSqlConnectorName + $global:sqlServerName.SubString($global:sqlServerName.Length-1,1))
    $global:BasicLogicAppName = ($config.Config.ResourceGroupSettings.Basic.BasicLogicAppName + $global:sqlServerName.SubString($global:sqlServerName.Length-1,1))

    # dynamic name 
    $global:ResourceGroupName = "ResourceGroup4" + $global:appName
    $global:ServicePlanName = "ServicePlan4" + $global:appName
    $global:storageAccountName = "crmconnectorcn" + $global:environment








}


