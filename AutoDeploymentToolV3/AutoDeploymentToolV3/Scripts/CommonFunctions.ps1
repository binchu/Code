function Replace($jsonInput, $jsonOutput){    
    $xml = [xml](Get-Content "ConfigurationSettings\Replace.xml")
    $nodes = $xml.Config.File | where {$_.name -eq $jsonInput}  
    $text = Get-Content ("$pwd\Templates\"+$jsonInput)
    foreach ($node in $nodes.kv) {
        $key = ("##"+$node.key+"##")
        $value = Invoke-Expression $node."#text"
        #Write-Output ("[" + $key + "] => [" + $value + "]")
        $text = $text -Replace $key, $value
    }
    $text | Out-File -Encoding ASCII ("$pwd\Templates\"+$jsonOutput)
}
