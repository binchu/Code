# input params
param(
    [Parameter(Mandatory=$true)][String]$ScriptPath =''
)

cd $ScriptPath

# import functions
.("$ScriptPath\Scripts\GetGlobalVariables.ps1")
.("$ScriptPath\Scripts\CommonFunctions.ps1")
.("$ScriptPath\Scripts\LoginInAzureAccount.ps1")
.("$ScriptPath\Scripts\CreateBasicResourceGroup.ps1")
.("$ScriptPath\Scripts\CreateDB.ps1")
.("$ScriptPath\Scripts\CreateAzureStorage.ps1")
.("$ScriptPath\Scripts\CreateBasicLogicApps.ps1")
.("$ScriptPath\Scripts\CreateEntityLogicApps.ps1")

# initialize
GetGlobalVariables

# running
LoginAzure
CreateBasicResourceGroup # resourcegroup4crmazure
CreateDB  ## only first time create server will ceate geo-server.
CreateAzureStorage # store the connector.zip
CreateBasicLogicApps # create logicapp4Clearlog
CreateEntityLogicApps # create logicapp4crmconnectorcontact, logicapp4contact





