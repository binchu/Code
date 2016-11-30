function LoginAzure{
    ## Add Azure Account ##
    Try
    {
        Add-AzureRmAccount  
        Import-AzurePublishSettingsFile $global:subscriptionDataFile
        Get-AzureRmSubscription -SubscriptionName $global:selectedSubscription | Select-AzureRmSubscription
        
        select-azuresubscription $global:selectedsubscription
        
        write-output $global:selectedSubscription
        Write-Output "$(Get-Date -f $timeStampFormat) - Azure Account has been successfully logged in."
    }
    Catch [Exception] 
    {  
        Write-Output $_.Exception.GetType().FullName; 
        Write-Output $_.Exception.Message;
        Write-Output "$(Get-Date -f $timeStampFormat) - Error occurred during login in azure account."
    }

}
