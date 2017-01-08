#parameters defined , should be passed from the command prompt or Ms arguments
#param( [Parameter(Mandatory=$true)][string]$ProjName,[Parameter(Mandatory=$true)][Int32]$ChangeSetNo,[Parameter(Mandatory=$true)][string]$DropLoc)

param( [Parameter(Mandatory=$true)][string]$ConfigFilePath)

#Loading the properties file to read all the properties
$file_content = Get-Content $ConfigFilePath
$file_content = $file_content -replace '\\', '\\'
$file_content = $file_content -join [Environment]::NewLine
$configuration = ConvertFrom-StringData($file_content)
# - end of reading

# Team foundation parameter
$teamProjectName= $configuration.teamProjectName #$ProjName  #team project NameSQLLogPath=C:\AIG\Logs
$tempworkspace= $configuration.Tempworkspace #$DropLoc      #$TargetLoc #target location
$SourceCodeFolder =$configuration.SourceCodeFolderName
$tfsurl=$configuration.tfsurl
$tfsCollection=$configuration.collectionName

Write-Host "Parameters details :" $teamProjectName + " " + $SourceCodeFolder + " " $tempworkspace
#end of parameters

#@start->DeleteTargerFolder
function DeleteTargerFolder
{
    $folder =$args[0]
     If (Test-Path $folder)
     {
        Remove-Item $folder -Recurse
        new-item $folder -type directory
      }
      else
       {
         new-item $folder -type directory 
       }
}
#end->DeleteTargerFolder


#start ->CreateFolder
function CreateFolder{
 
      $folder =$args[0]
     If (Test-Path $folder)
     {
        Write-Host $folder +  " folder exists"
        Remove-Item $folder -Recurse
        new-item $folder -type directory
      }
      else
       {
         new-item $folder -type directory 
       }
}
#end -> CreateFolder


#start->DownloadSourceCodeFromTFS
Function DownloadSourceCodeFromTFS
{
  $tfslocalFolderPath="$/"+ $teamProjectName +"/"+ $SourceCodeFolder + "/*"
   $vscHistory=$versionControlServer.QueryHistory($tfslocalFolderPath,[Microsoft.TeamFoundation.VersionControl.Client.VersionSpec]::Latest,0,'Full', $null, $null,$null, [int32]::MaxValue, $true ,$true, $false)
   $TargetChangeSetChangeItems = @()  
   $TargetChangeSetChangeItems = foreach ($vCSChangeSet in $vscHistory) 
    {   
       # $changeSetFolder =$targetserloc+ "Changeset_"+ $vCSChangeSet.ChangesetId +"\"
        #CreateFolder $changeSetFolder
        Write-Host "File(s) are downloading from TFS......"
        foreach ($vCSChange in $vCSChangeSet.Changes) 
        { 
            $vCSItem =  $vCSChange.Item 
            if ($vCSItem.ItemType -eq "File" )
                {
                 $vCSItem.DownloadFile($tempworkspace +$vCSItem.ServerItem.Tostring().Substring(2))
                }
        }
        Write-Host "Download completed..."
    }
   
}


# Code - for connecting to Team foundation server and download files for a particular changeset
try
{
    #Deleting the temporary work space and download again latest source code from  TFS
    DeleteTargerFolder  $tempworkspace
    
    # Add TFS 2013 dlls so we can download some files
    # The version needs to be  modified based on the dlls deployed on the build server
    #Load Reference Assemblies
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")  
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Client")  
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Common") 
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.WorkItemTracking.Client")
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.VersionControl.Client")

   
   
    $CollectionUrl=$tfsurl+"/"+$tfsCollection

    $tfsConfigurationServer = [Microsoft.TeamFoundation.Client.TfsConfigurationServerFactory]::GetConfigurationServer($tfsurl)
    $tpcService = $tfsConfigurationServer.GetService("Microsoft.TeamFoundation.Framework.Client.ITeamProjectCollectionService")

    $tfsCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($CollectionUrl)

    $workItemstore = $TfsCollection.GetService([Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore])
    $cssService = $TfsCollection.GetService("Microsoft.TeamFoundation.Server.ICommonStructureService3")   
    $versionControlServer = $TfsCollection.GetService("Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer")

    $proj = $workItemstore.Projects[$teamprojectName] 
    
    Write-Host "Team project name :" $proj.Name
     
    #checking for changesets  - and downloading the file(s) based on ChangesetIDs
     $SourcePath=$targetserloc + $teamProjectName   
     DownloadSourceCodeFromTFS
     }
#Error of TFS connection
catch
{
    Write-Host $Error[0] -ForegroundColor Red
    exit 1
}
