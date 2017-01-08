param( [Parameter(Mandatory=$true)][string]$ConfigFilePath, 
        [Parameter(Mandatory=$false)][string]$PublishProfile)

    $file_content = Get-Content $ConfigFilePath
    $file_content = $file_content -replace '\\', '\\'
    $file_content = $file_content -join [Environment]::NewLine
    $configuration = ConvertFrom-StringData($file_content)
    
   
   

#start ->DownloadFileForaSingleChangeSetId
function BuildNetProjects
{    
    $sourceCodeFolder=$args[0]
    $slnName=$args[1]
    
     $msbuildArguments=""
    
    $msbuildArguments = $msbuildArguments + '/p:Configuration='+ $buildconfiguration+';outputdir='+ $buildOutPutDir+';DeployOnBuild=true;CreatePackage=true;PackageLocation='+$packageLoc
    
    if ($PublishProfile)
    {
            $publishProfile=$PublishProfile
            $msbuildArguments =$msbuildArguments +  ';DeployOnBuild=true;CreatePackage=true;PublishProfile='+$publishProfile 
    }
    
    Write-Host "Msbuild Arguments - $msbuildArguments"
    
    if(Test-Path $sourceCodeFolder) 
    {
        $solutionToBuild =$sourceCodeFolder + '\' + $slnName
        Write-Host "Building $solutionToBuild"
        & $msbuild $solutionToBuild /t:rebuild /p:PlatformTarget=x86 /fl  $msbuildArguments "/flp1:logfile=$sourceCodeFolder\msbuild.log;Verbosity=Normal;Append;"
        #& $devenv $projectFileAbsPath /Rebuild
        
        if($LASTEXITCODE -eq 0)
        {
            Write-Host "Build SUCCESS" -ForegroundColor Green
            #Clear-Host
            break
        }
        else
        {
             Write-Host "Build Failder" -ForegroundColor Red
            Clear-Host
        }
        
    }
    else
    {
        Write-Host "File does not exist : $SourceCodePath"
        Start-Sleep -s 5
        break
    }    
 }

try
{
    
    
    # Team foundation parameter
    
    $SoultionName= $configuration.soultionName
    $SourceCodePath =$configuration.sourceCodePath
    $BuildDrops= $configuration.BuildDropLoc
    $msbuild =$configuration.msbuildexe 
    $buildconfiguration=$configuration.configurationMode
    $buildOutPutDir=$configuration.buildOutPutDir
    $packageLoc=$configuration.packageLoc

  BuildNetProjects $SourceCodePath $SoultionName $buildconfiguration
    
 }
#Error of TFS connection
catch
{
    Write-Host $Error[0] -ForegroundColor Red
    exit 1
}




#end -> CopyFilesFromTargetLocationtoSpecifiedfoder

# Code - for connecting to Team foundation server and download files for a particular changeset

