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

function Write-PathNameForKeyToConfig ($key, $extensionFilter) {
    $value = Get-FileName $extensionFilter $key
    Write-ToConfig $key $value
}
   
function Write-FreeTextForKeyToConfig ($key, $prompt) {
    $value = Get-FreeText $key $prompt
    Write-ToConfig $key $value
}

function Write-SplitPathToConfig($key, $extensionFilter, $prompt) {
    Write-Host $prompt
    $path = Get-FileName $extensionFilter $prompt
    $folder = Split-Path -Path $path
    Write-ToConfig "$($key)Folder" $folder
    $file = Split-Path -Path $path -Leaf
    Write-ToConfig "$($key)File" $file
}

function ConfigViaGUI () {

    Write-Host "Deleting Previous Configuration..."

    # Replace/Create a .config file and write the header
    "key,value" | Out-File .\molt.config

    Write-Host "Select your After Effects Project"
    Write-PathNameForKeyToConfig "projectPath" "After Effects Project | *.aep"
    Write-SplitPathToConfig "source" "Illustrator File | *.ai" "The current source file" "Select the source file currently being used in the After Effects Project"
    Write-FreeTextForKeyToConfig "outputModuleTemplate" "Enter the (case sensitive) name of your After Effects Output Module Template"
    Write-FreeTextForKeyToConfig "compName" "Enter the (case sensitive) name of your After Effecs Comp"
    Write-Host 
    Write-SplitPathToConfig "output" "AnyFile| *" "Select a file in the output directory named <prefix>"
}


ConfigViaGUI

