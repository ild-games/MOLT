<#set exePath="C:\Program Files\Adobe\Adobe After Effects CC 2017\Support Files\aerender.exe"
set projectPath="D:\Projects\GeneralArtPractice\AESkinProofOfConcept\AEProject\AESkinProofOfConcept.aep"
set compName="Test"
set outputModuleTemplate="PNGSequenceSingleFrameRGBA"
::The outputPath includes the [#] wildcard because AE needs a placeholder for frames and will append after the .png if we don't have it
set outputPath="D:\Projects\GeneralArtPractice\AESkinProofOfConcept\Renders\compName[#].png" 


%exePath% -help
%exePath% -project %projectPath% -comp %compName% -OMtemplate %outputModuleTemplate% -output %outputPath%
pause
#>

function Get-Value($key) {
    $csvResults = Import-Csv .\molt.config | Where-Object {$_.key -eq $key}
    ForEach-Object -InputObject $csvResults {
        $returnValue = $_.value
    }
    $returnValue
}

function AERenderUsingSource($sourceFile) {
    $previousName = Split-Path -Path $sourceFile -Leaf
    Write-Host $previousName
    #Rename the source file to the name of the working source

    #Name it back to its original name

}

function Rename ($path, $file, $newName) {
    Rename-Item -Path "$($path)\$($file)" -NewName "$($path)\$($newName)"
}


#Get Values from config file
$projectFile = Get-Value "projectFile"
$sourceFile = Get-Value "sourceFile"
$sourceFolder = Split-Path -Path "$($sourceFile)"
$sourceFile = $sourceFile | Split-Path -Leaf

#Rename 

$tempOriginalFileName = "MOLTOriginal.ai"
Rename $sourceFolder $sourceFile $tempOriginalFileName
$sourceFolder | Get-ChildItem -Filter "*.ai" | ForEach-Object { AERenderUsingSource $_.Name }
Write-Host $projectFile
Write-Host $sourceFolder
Write-Host $sourceFile

cmd /c pause | out-null
Rename $sourceFolder $tempOriginalFileName $sourceFile
