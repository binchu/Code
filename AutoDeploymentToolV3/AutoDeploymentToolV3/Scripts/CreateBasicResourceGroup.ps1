
function CreateBasicResourceGroup{
    <#
    if($global:deleteRG){
        Remove-AzureRmResourceGroup -name  $global:BasicResourceGroupName
    }#>

    $global:CurrentServicePlanName = $global:BasicServicePlanName
    Replace ResourceGroupAndServicePlan.Param.json ResourceGroupAndServicePlan1.Param.json

    New-AzureRmResourceGroup -Name $global:BasicResourceGroupName -Location $global:BasicResourceGroupLocation -Force -Verbose
    New-AzureRmResourceGroupDeployment -ResourceGroupName $global:BasicResourceGroupName -TemplateFile "$pwd\Templates\ResourceGroupAndServicePlan.json" -TemplateParameterFile "$pwd\Templates\ResourceGroupAndServicePlan1.Param.json" -Force -Verbose
}
