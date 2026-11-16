# Builds a GOG physical-media launcher without requiring the game's EXE name.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-GameFiles {
    if (-not (Test-Path -LiteralPath $mediaFolder.Text -PathType Container)) { return }
    $files = Get-ChildItem -LiteralPath $mediaFolder.Text -File -ErrorAction SilentlyContinue
    $script:installerName = ($files | Where-Object { $_.Extension -ieq '.exe' -and $_.Name -like 'setup*.exe' } | Select-Object -First 1).Name
    $script:iconPath = ($files | Where-Object { $_.Extension -ieq '.ico' } | Select-Object -First 1).FullName
    if ([string]::IsNullOrWhiteSpace($titleBox.Text)) { $titleBox.Text = Split-Path -Leaf $mediaFolder.Text }
    $installerText = if ($script:installerName) { $script:installerName } else { 'NOT FOUND' }
    $iconText = if ($script:iconPath) { Split-Path -Leaf $script:iconPath } else { 'NOT FOUND' }
    $foundInfo.Text = "Found automatically:`r`nInstaller: $installerText`r`nIcon: $iconText"
}

function Assert-SafeText([string]$Value, [string]$Field) {
    if ([string]::IsNullOrWhiteSpace($Value)) { throw "$Field is required." }
    if ($Value.IndexOfAny([char[]]'&|<>^!%"') -ge 0 -or $Value.Contains("`r") -or $Value.Contains("`n")) { throw ('{0} contains a character that cannot be used safely in this launcher: & | < > ^ ! % "' -f $Field) }
}

function Write-GameFinder([string]$Destination) {
    $finder = @'
param([Parameter(Mandatory = $true)][string]$GameTitle)
$roots = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
$app = foreach ($root in $roots) { Get-ItemProperty -Path $root -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and ($_.DisplayName -eq $GameTitle -or $_.DisplayName -like "*$GameTitle*") -and $_.InstallLocation } }
foreach ($item in $app) {
    $location = $item.InstallLocation.Trim()
    $info = Get-ChildItem -LiteralPath $location -Filter 'goggame-*.info' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $info) { continue }
    try { $game = Get-Content -LiteralPath $info.FullName -Raw | ConvertFrom-Json } catch { continue }
    $task = $game.playTasks | Where-Object { $_.isPrimary -eq $true -and $_.path } | Select-Object -First 1
    if (-not $task) { $task = $game.playTasks | Where-Object { $_.path } | Select-Object -First 1 }
    if (-not $task) { continue }
    $executable = Join-Path $location $task.path
    if (Test-Path -LiteralPath $executable) { Start-Process -FilePath $executable -WorkingDirectory $location; exit 0 }
}
exit 1
'@
    [IO.File]::WriteAllText($Destination, $finder.Replace("`n", "`r`n"), [Text.Encoding]::UTF8)
}

function Write-InstallBat([string]$Destination, [string]$GameTitle, [string]$InstallerName) {
    $bat = @"
@echo off
setlocal
set "DISC_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DISC_DIR%launch-installed-gog-game.ps1" "$GameTitle" >nul 2>nul
if not errorlevel 1 exit /b
if exist "%DISC_DIR%$InstallerName" (
    start "" "%DISC_DIR%$InstallerName"
    exit /b
)
echo ERROR: The GOG installer was not found on this media.
pause
"@
    [IO.File]::WriteAllText($Destination, $bat.Replace("`n", "`r`n"), [Text.Encoding]::ASCII)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'GOG Physical Media Builder'
$form.ClientSize = New-Object System.Drawing.Size(690, 410)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$heading = New-Object System.Windows.Forms.Label
$heading.Text = 'Create a GOG DVD / SSD launcher - no game EXE name needed'
$heading.Location = New-Object System.Drawing.Point(16, 15)
$heading.Size = New-Object System.Drawing.Size(650, 26)
$heading.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($heading)

$step1 = New-Object System.Windows.Forms.Label
$step1.Text = '1. Choose the folder that already contains this game''s GOG setup EXE and icon.'
$step1.Location = New-Object System.Drawing.Point(16, 54)
$step1.Size = New-Object System.Drawing.Size(650, 20)
$form.Controls.Add($step1)
$mediaFolder = New-Object System.Windows.Forms.TextBox
$mediaFolder.Location = New-Object System.Drawing.Point(20, 79)
$mediaFolder.Size = New-Object System.Drawing.Size(545, 24)
$form.Controls.Add($mediaFolder)
$choose = New-Object System.Windows.Forms.Button
$choose.Text = 'Choose folder...'
$choose.Location = New-Object System.Drawing.Point(574, 77)
$choose.Size = New-Object System.Drawing.Size(100, 28)
$choose.Add_Click({ $dialog = New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.Description = 'Choose this game''s GOG media folder'; if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $mediaFolder.Text = $dialog.SelectedPath; Get-GameFiles } })
$form.Controls.Add($choose)

$foundInfo = New-Object System.Windows.Forms.Label
$foundInfo.Text = 'The setup EXE and ICO will be found automatically after you choose a folder.'
$foundInfo.Location = New-Object System.Drawing.Point(20, 117)
$foundInfo.Size = New-Object System.Drawing.Size(654, 52)
$foundInfo.BorderStyle = 'FixedSingle'
$foundInfo.Padding = New-Object System.Windows.Forms.Padding(7, 5, 7, 5)
$form.Controls.Add($foundInfo)

$step2 = New-Object System.Windows.Forms.Label
$step2.Text = '2. Type the game title as GOG shows it in your Library or on its installer screen.'
$step2.Location = New-Object System.Drawing.Point(16, 188)
$step2.Size = New-Object System.Drawing.Size(650, 20)
$form.Controls.Add($step2)
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = 'GOG game title (example: DOOM + DOOM II)'
$titleLabel.Location = New-Object System.Drawing.Point(20, 216)
$titleLabel.Size = New-Object System.Drawing.Size(400, 18)
$form.Controls.Add($titleLabel)
$titleBox = New-Object System.Windows.Forms.TextBox
$titleBox.Location = New-Object System.Drawing.Point(20, 238)
$titleBox.Size = New-Object System.Drawing.Size(654, 24)
$form.Controls.Add($titleBox)

$why = New-Object System.Windows.Forms.Label
$why.Text = 'On later runs, the launcher reads GOG installed-game data to discover and start the correct EXE automatically.'
$why.Location = New-Object System.Drawing.Point(20, 275)
$why.Size = New-Object System.Drawing.Size(650, 38)
$form.Controls.Add($why)

$build = New-Object System.Windows.Forms.Button
$build.Text = 'Create install.bat and autorun.inf'
$build.Location = New-Object System.Drawing.Point(421, 350)
$build.Size = New-Object System.Drawing.Size(253, 34)
$build.Add_Click({
    try {
        if (-not (Test-Path -LiteralPath $mediaFolder.Text -PathType Container)) { throw 'Choose an existing game media folder.' }
        Get-GameFiles
        Assert-SafeText $titleBox.Text 'GOG game title'
        if (-not $script:installerName) { throw 'No setup EXE was found. It should be named setup_...exe and be in the selected folder.' }
        if (-not $script:iconPath) { throw 'No ICO file was found in the selected folder.' }
        $root = (Resolve-Path -LiteralPath $mediaFolder.Text).Path
        $iconDestination = Join-Path $root 'game.ico'
        if ((Resolve-Path -LiteralPath $script:iconPath).Path -ne $iconDestination) { Copy-Item -LiteralPath $script:iconPath -Destination $iconDestination -Force }
        Write-GameFinder (Join-Path $root 'launch-installed-gog-game.ps1')
        Write-InstallBat (Join-Path $root 'install.bat') ($titleBox.Text.Trim()) $script:installerName
        $inf = "[autorun]`r`nopen=install.bat`r`nicon=game.ico`r`nlabel=$($titleBox.Text.Trim())`r`naction=Play $($titleBox.Text.Trim())`r`n"
        [IO.File]::WriteAllText((Join-Path $root 'autorun.inf'), $inf, [Text.Encoding]::ASCII)
        [System.Windows.Forms.MessageBox]::Show('Done. The selected folder now contains install.bat, autorun.inf, and the game finder helper.', 'GOG Physical Media Builder', 'OK', 'Information')
    } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Build failed', 'OK', 'Error') }
})
$form.Controls.Add($build)
$form.Add_Shown({ $mediaFolder.Focus() })
[void]$form.ShowDialog()
