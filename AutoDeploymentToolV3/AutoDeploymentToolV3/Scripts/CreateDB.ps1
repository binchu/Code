
function CreateDB{		
	Replace Database.param.json Database1.param.json

	write-host $global:sqlServerName
	write-host $global:BasicResourceGroupName

	$server = Get-AzureRmSqlServer -ServerName $global:sqlServerName -ResourceGroupName $global:BasicResourceGroupName
	$flag = $false
	if(!$server){
		Write-Output 'need create db server'
		New-AzureRmResourceGroupDeployment -ResourceGroupName $global:BasicResourceGroupName -TemplateFile "$pwd\Templates\DataBase.json" -TemplateParameterFile "$pwd\Templates\Database1.param.json" -Force -Verbose
		$server = Get-AzureRmSqlServer -ServerName $global:sqlServerName -ResourceGroupName $global:BasicResourceGroupName
		$flag = $true
	} 

	$version = $server.ServerVersion
	$firstVersion = $true
	while($version -ne "12.0"){
		Write-Output 'Waiting Sql Server to upgrade to V12'
		if($firstVersion){
			Start-AzureRmSqlServerUpgrade -ResourceGroupName $global:BasicResourceGroupName -ServerName $global:sqlServerName -ServerVersion 12.0 	
			$firstVersion = $false;
		}
		Start-Sleep -s 60
		$server = Get-AzureRmSqlServer -ServerName $global:sqlServerName -ResourceGroupName $global:BasicResourceGroupName
		$version = $server.ServerVersion 
	}
	
	# add rule to allow azure service to visit DataBase
	$rules = Get-AzureSqlDatabaseServerFirewallRule -servername $global:sqlServerName
	if(!$rules.Rulename.contains('AllowAllAzureServices')){
		$server | New-AzureSqlDatabaseServerFirewallRule -AllowAllAzureServices 
	}

	$dbObj = Get-AzureRmSqlDatabase -ServerName $global:sqlServerName -ResourceGroupName $global:BasicResourceGroupName -DatabaseName $global:sqlDatabaseName
	if(!$dbObj){
		Write-Output 'need create database'
		New-AzureRmResourceGroupDeployment -ResourceGroupName $global:BasicResourceGroupName -TemplateFile ".\Templates\DataBaseV12.json" -TemplateParameterFile ".\Templates\Database1.param.json" -Force -Verbose
		
		$dbObj = Get-AzureRmSqlDatabase -ServerName $global:sqlServerName -ResourceGroupName $global:BasicResourceGroupName -DatabaseName $global:sqlDatabaseName
	}

	$firstEdition = $true
	$dbEdition = $dbObj.Edition
	$dbServiceObject = $dbObj.CurrentServiceObjectiveName 
	while($dbEdition -ne "Premium" -or $dbServiceObject -ne "P6"){
		Write-Output 'Waiting DB to upgrade to P6'
		$NewEdition = "Premium"
		$NewPricingTier = "P6"
		if($firstEdition){
			Set-AzureRmSqlDatabase -DatabaseName $global:sqlDatabaseName -ServerName $global:sqlServerName -ResourceGroupName $global:BasicResourceGroupName -Edition $NewEdition -RequestedServiceObjectiveName $NewPricingTier
			$firstEdition = $false;	
		}
		Start-Sleep -s 20
		$dbObj = Get-AzureRmSqlDatabase -ServerName $global:sqlServerName -ResourceGroupName $global:BasicResourceGroupName -DatabaseName $global:sqlDatabaseName
		$dbEdition = $dbObj.Edition
		$dbServiceObject = $dbObj.CurrentServiceObjectiveName 
	}

	Set-AzureSqlDataBase -servername $global:sqlServerName -databasename $global:sqlDatabaseName -maxsizegb 20 
	
	# deploy dacpac to database
	#
	$sqlpackage = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\120\sqlpackage.exe"
	Replace DatabaseProfile.xml DatabaseProfile1.xml
	$mydacpac = ("$pwd\Package\" + $global:dacpacFile)
	$dbProfile = "$pwd\Templates\DatabaseProfile1.xml"

	& $sqlpackage /Action:Publish /sf:$mydacpac /pr:$dbProfile /p:BlockOnPossibleDataLoss=False
	& $sqlpackage /Action:Publish /sf:$mydacpac /pr:$dbProfile /p:BlockOnPossibleDataLoss=False
	
	### geo-replication
	if($flag -and ($global:geoFlag -eq "1")){
		Write-Output 'geo replication'
		$geoServerName = ("georep" + $global:sqlServerName)
		$geoLocation = "East US"
		$geoResourceGroup = ("RG4" + $geoServerName)
			
		# create geo resource group and geo server for secondary db
		New-AzureRmResourceGroup -Name $geoResourceGroup -Location $geoLocation -Force -Verbose
		$geoObj = Get-AzureRmSqlServer -ServerName $geoServerName -ResourceGroupName $geoResourceGroup		
		if(!$geoObj){
			Write-Output 'need create geo db server'
			$GeoPassword = ConvertTo-SecureString $global:sqlPassword -AsPlainText -Force
			$geoCredentials = New-Object System.Management.Automation.PSCredential ($global:sqlUserName, $GeoPassword)
			New-AzureRmSqlServer -ResourceGroupName $geoResourceGroup -Location $geoLocation -ServerName $geoServerName -SqlAdministratorCredentials $geoCredentials
			$geoObj = Get-AzureRmSqlServer -ServerName $geoServerName -ResourceGroupName $geoResourceGroup			
		} 

		$geoversion = $geoObj.ServerVersion
		$firstgeoVersion = $true
		while($geoversion -ne "12.0"){
			Write-Output 'Waiting Geo Sql Server to upgrade to V12'
			if($firstgeoVersion){
				Start-AzureRmSqlServerUpgrade -ResourceGroupName $geoResourceGroup -ServerName $geoServerName -ServerVersion 12.0 
				$firstgeoVersion = $false;
			}
			Start-Sleep -s 60
			$geoObj = Get-AzureRmSqlServer -ServerName $geoServerName -ResourceGroupName $geoResourceGroup
			$geoVersion = $geoObj.ServerVersion 
		}

		# create secondary database
		$database = Get-AzureRmSqlDatabase –DatabaseName $global:sqlDatabaseName -ServerName $global:sqlServerName -ResourceGroupName $global:BasicResourceGroupName
		$secondaryLink = $database | New-AzureRmSqlDatabaseSecondary –PartnerResourceGroupName $geoResourceGroup –PartnerServerName $geoServerName -AllowConnections "All"
		
		$rules = Get-AzureSqlDatabaseServerFirewallRule -servername $geoServerName
		write-output $rules
		if(!$rules -or !$rules.Rulename.contains('AllowAllAzureServices')){
			write-output 'create allow all azure services rule'
			$geoObj | New-AzureSqlDatabaseServerFirewallRule -AllowAllAzureServices 
		}
		if(!$rules -or !$rules.Rulename.contains('WhiteList')){
			write-output 'create whitelist ip rule'
			New-AzureSqlDatabaseServerFirewallRule -ServerName $geoServerName -RuleName "WhiteList" -StartIpAddress 0.0.0.0 -EndIpAddress 255.255.255.255
		}
		# if failover, use secondary db	
		<#
		$secondaryDatabase = Get-AzureRmSqlDatabase –DatabaseName $global:sqlDatabaseName –ResourceGroupName $geoResourceGroup –ServerName $geoServerName
		$secondaryDatabase | Set-AzureRmSqlDatabaseSecondary -Failover -PartnerResourceGroupName $global:BasicResourceGroupName -AllowDataLoss
		#>
		
	}	
}
