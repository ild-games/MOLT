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

function Rename ($folder, $file, $newName) {
    Rename-Item -Path "$($folder)\$($file)" -NewName "$($folder)\$($newName)"
}

function Get-OutputPathTemplate($sourceFileName) {
    $prefix = Get-Value "outputFile"
    $folder = Get-Value "outputFolder"

    $fileName = "$($prefix)_$($sourceFileName)[#]"
    "$($folder)\$($fileName)"
}

function ExecuteAERender($outputName) {
    $projectPath = Get-Value "projectPath"
    $compName = Get-Value "compName"
    $outputModuleTemplate = Get-Value "outputModuleTemplate"
    $outputPath = Get-OutputPathTemplate $outputName

    aerender.exe -reuse -project $projectPath -comp $compName -OMtemplate $outputModuleTemplate -output $outputPath
}

function AERenderUsingSource($sourceFolder, $currentSourceFile,  $workingSourceFile) {

    Rename $sourceFolder $currentSourceFile $workingSourceFile
    $outputName = $currentSourceFile
    if ($outputName -eq "MOLTOriginal.ai"){
        $outputName = $workingSourceFile
    }
    ExecuteAERender $outputName
    Rename $sourceFolder $workingSourceFile $currentSourceFile
}



#Get Values from config file
$projectPath = Get-Value "projectPath"
$workingSourceFile = Get-Value "sourceFile"
$sourceFolder = Get-Value "sourceFolder"

#Rename the original 
$tempOriginalFileName = "MOLTOriginal.ai"
Rename $sourceFolder $workingSourceFile $tempOriginalFileName

# #Render once for each AI File
$sourceFolder | Get-ChildItem -Filter "*.ai" | ForEach-Object { AERenderUsingSource $sourceFolder $_.Name $workingSourceFile }

Rename $sourceFolder $tempOriginalFileName $workingSourceFile


cmd /c pause | out-null
