#param( [Parameter(Mandatory=$true)][string]$ConfigFilePath, 
 #       [Parameter(Mandatory=$true)][string]$Environment)

  $ConfigFilePath="D:\SchwabTest\Deploy.config"
  $Environment="devp"
  
    $file_content = Get-Content $ConfigFilePath
    $file_content = $file_content -replace '\\', '\\'
    $file_content = $file_content -join [Environment]::NewLine
    $configuration = ConvertFrom-StringData($file_content)
        
   

#start ->DownloadFileForaSingleChangeSetId
function DeployWebapplication
{ 
    $PackageVal=$PackageDir +'\'+ $Package    
    $packageArg =  '-source:package='+'"'+$PackageVal+'"'
    $deployUrl="http://"+$ServerName+"/MSDeployAgentService"
    Write-Host "DeployUrl:-$deployUrl"
    $destArg='-dest:auto,computerName='+'"'+ $deployUrl+'"'+',userName='+'"'+$userName+'"'+',password='+'"'+$password+'"'+',authtype='+'"'+ $authType+'"'+',includeAcls='+'"'+$isIncldeAcls+'"'
    Write-Host "destArg:-$destArg"
    $verbArg='-verb:sync'
    $paramArg='-setParamFile:'+'"'+$PackageParamter +'"'
    $otherArg='-whatif -allowUntrusted'    
    
    Write-Host $msDeploy $packageArg $destArg $verbArg $paramArg $otherArg
    
   & $msDeploy $packageArg $destArg $verbArg $paramArg 
   
    
 }
  
try
{
  $msDeploy=$configuration.msdelpoyexe
  
  Write-Host "msdeploy: $msDeploy"
  
  if ( $Environment -eq "Devp")
  {
    $PackageDir = $configuration.PackageDir
    $Package=$configuration.Package
    $DeployCmdFile=$configuration.DeployCmdFile
    $ServerName=$configuration.dev_McName
    $siteName=$configuration.dev_siteName
    $PackageParamter=$configuration.setParamFilePath  
    $userName=$configuration.dev_username
    $password=$configuration.dev_password
    $authType='NTLM' #$configuration.dev_authtype
    $isIncldeAcls=$configuration.dev_includeAcls
    $verb=$configuration.dev_verb
  
  }
  Elseif ( $Environment -eq "Test")
  {
    $PackageDir = $configuration.PackageDir
    $Package=$configuration.Package
    $DeployCmdFile=$configuration.DeployCmdFile  
    $ServerName=$configuration.test_McName
    $siteName=$configuration.test_siteName
    $PackageParamter=$configuration.setParamFilePath  
    $userName=$configuration.test_username
    $password=$configuration.test_password
    $authType='NTLM' #$configuration.test_authtype
    $isIncldeAcls=$configuration.test_includeAcls
    $verb=$configuration.test_verb
  }
  else
  {
    Write-Host "please select the environment values properly"
    exit 1
  }
  
   DeployWebapplication 
    
 }
#Error of TFS connection
catch
{
    Write-Host $Error[0] -ForegroundColor Red
    exit 1
}




#end -> CopyFilesFromTargetLocationtoSpecifiedfoder

# Code - for connecting to Team foundation server and download files for a particular changeset

