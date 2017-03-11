function Get-FileName ($extensionFilter, $title) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

    $FileSelectionDialog = New-Object System.Windows.Forms.OpenFileDialog
    $FileSelectionDialog.Title = $title
    $FileSelectionDialog.Filter = $extensionFilter
    $FileSelectionDialog.ShowDialog() | Out-Null

    $FileSelectionDialog.FileName
}

function Get-ContainerDialog($title) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

    $freeTextForm = New-Object System.Windows.Forms.Form
    $freeTextForm.Text = $title
    $freeTextForm.Size = New-Object System.Drawing.Size(300,200)
    $freeTextForm.StartPosition = "CenterScreen"

    $freeTextForm
}

function Get-OKButton($TextBox, $freeTextForm) {
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(75,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $OKButton
}

function Get-Prompt($text) {
    $prompt = New-Object System.Windows.Forms.Label
    $prompt.Location = New-Object System.Drawing.Size(10,20) 
    $prompt.Size = New-Object System.Drawing.Size(280,20) 
    $prompt.Text = $text
    $prompt
}

function Get-TextBox() {
    $textBox = New-Object System.Windows.Forms.TextBox 
    $textBox.Location = New-Object System.Drawing.Size(10,40) 
    $textBox.Size = New-Object System.Drawing.Size(260,20) 
    $textBox
}

function Get-FreeText ($title, $prompt) {
    Read-Host $prompt
}

function Write-ToConfig ($key, $value) {
    "$($key),$($value)" | Out-File .\molt.config -Append
}

function Write-FileNameForKeyToConfig ($key, $extensionFilter) {
    $value = Get-FileName $extensionFilter $key
    Write-ToConfig $key $value
}

function Write-FreeTextForKeyToConfig ($key, $prompt) {
    $value = Get-FreeText $key $prompt
    Write-ToConfig $key $value
}

function ConfigViaGUI () {

    Write-Host "Deleting Previous Configuration..."

    # Replace/Create a .config file and write the header
    "key,value" | Out-File .\molt.config

    Write-Host "Select your After Effects Project"
    Write-FileNameForKeyToConfig "projectFile" "After Effects Project | *.aep"
    Write-Host "Select the source file currently being used in the After Effects Project"
    $sourcePath = Get-FileName "Illustrator File | *.ai" "The current source file"
    $sourceFolder = Split-Path -Path $sourcePath
    $sourceFile = Split-Path -Path $sourcePath -Leaf
    Write-ToConfig "sourceFolder" $sourceFolder
    Write-ToConfig "sourceFile" $sourceFile
    Write-FreeTextForKeyToConfig "outputModuleTemplate" "Enter the (case sensitive) name of your After Effects Output Module Template"
    Write-FreeTextForKeyToConfig "compName" "Enter the (case sensitive) name of your After Effecs Comp"
    Write-Host "Select a .png file with the naming scheme desired for your output "
    Write-FileNameForKeyToConfig "outputFile" "PNG Image | .png"
}


ConfigViaGUI


