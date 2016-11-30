function CreateAzureStorage{
    $global:storageAccountName = $global:storageAccountName.ToLower()
    $sName = Get-AzureRmStorageAccount -Name $global:storageAccountName -ResourceGroupName $global:BasicResourceGroupName
    if(!$sName){
        New-AzureRmStorageAccount -Name $global:storageAccountName -Location $global:storageAccountLocation -ResourceGroupName $global:BasicResourceGroupName -Type Standard_GRS -Verbose
    }

    Set-AzureRmCurrentStorageAccount -ResourceGroupName $global:BasicResourceGroupName -StorageAccountName $global:storageAccountName

    $sContainer = Get-AzureStorageContainer -Name $global:containerName
    if(!$sContainer){
        New-AzureStorageContainer -Name $global:containerName -Permission "Blob" -Verbose
    }
    Set-AzureStorageBlobContent -Container $global:containerName -File ("$pwd\Package\"+$global:zipToUpload) -Force 
    Write-Output "$(Get-Date -f $timeStampFormat) - Package been updated to according azure storage-container-blob."
}
