
function CreateBasicLogicApps {
		
	$sub = Get-AzureRmSubscription -SubscriptionName $global:selectedsubscription
	$subId = $sub.SubscriptionId


	if($global:BasicLAFalg -eq 1){
		$rc = $null
		$rc = Get-AzureRmResource -ResourceGroupName $global:BasicResourceGroupName -ResourceType Microsoft.AppService/apiapps -ResourceName $global:BasicSqlConnectorName
		if (!$rc ){ #create
			Write-Output ("Create Basic Logic App:" + $global:BasicLogicAppName)
			$ConnectorName = "MicrosoftSqlConnector"
			$ResourceIdPrefix = "/subscriptions/" + $subId + "/resourcegroups/" + $global:BasicResourceGroupName 

			$ApiAppDeploymentTemplate = Invoke-AzureRmResourceAction -Action generate -ApiVersion "2015-03-01-preview" -Force -ResourceId ($ResourceIdPrefix + "/providers/Microsoft.AppService/deploymenttemplates") -Parameters @{ "hostingPlan" = @{ "hostingPlanName" = $global:BasicServicePlanName }; "packages" = @(@{ "id" = $ConnectorName }) }

			$JSONTemplateString = (ConvertTo-Json -InputObject $ApiAppDeploymentTemplate.Value -Depth 20) | Out-File -FilePath "$pwd\Templates\Template_SqlConnector.json"


			$sqlconnector = (Get-Content -Raw -Path "$pwd\Templates\Template_SqlConnector.json" | ConvertFrom-Json)
			$sqlconnectorVarList = $sqlconnector.Variables.psobject.properties
			$sqlconnectorValue = ($sqlconnectorVarList | Where-Object {$_.name -Like "ApiApp*"}).Value
			$sqlconnectorSitename = $sqlconnectorValue.SiteName 
			$gatewayValue = ($sqlconnectorVarList | Where-Object {$_.name -Like "Gateway*"}).Value
			$gatewayName = $gatewayValue.GatewayName	
		}else{ #update
			Write-Output ("Update Basic Logic App:" + $global:BasicLogicAppName)

			$sqlconnectorSitename = $rc.Properties.Host.ResourceName
			$gatewayName = $rc.Properties.Gateway.ResourceName
			
		}
		$global:currentSqlConnectorName = $global:BasicSqlConnectorName
		$global:currentSqlConnectorSiteName = $sqlconnectorSitename
		$global:currentGatewayName = $gatewayName
		$global:currentlogicAppName = $global:BasicLogicAppName
		$global:currentServicePlanName = $global:BasicServicePlanName

		Replace BasicLA.json BasicLA1.json	
		Replace BasicLA.param.json BasicLA1.param.json
		New-AzureRmResourceGroupDeployment -ResourceGroupName $global:BasicResourceGroupName -TemplateFile "$pwd\Templates\BasicLA1.json" -TemplateParameterFile "$pwd\Templates\BasicLA1.param.json" -Force -Verbose

	}
	
}
