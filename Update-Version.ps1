param (
    [string]$ProjectFile = "TulipErrorInline.dproj"
)

$TargetFile = "$PWD\$ProjectFile"
if (-Not (Test-Path $TargetFile)) { 
    Write-Host "File $TargetFile not found." -ForegroundColor Red
    exit 1 
}

# Load XML file
$xml = New-Object System.Xml.XmlDocument
$xml.PreserveWhitespace = $true
$xml.Load($TargetFile)

$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace("msb", "http://schemas.microsoft.com/developer/msbuild/2003")

# Read current version reliably from VerInfo_Keys
$CurrentVersion = "1.0.0.0"
$keyNodes = $xml.SelectNodes("//msb:VerInfo_Keys", $ns)
if ($keyNodes) {
    foreach ($node in $keyNodes) {
        if ($node.InnerText -match 'FileVersion=(\d+\.\d+\.\d+\.\d+)') {
            $CurrentVersion = $matches[1]
            break
        }
    }
}

Write-Host "========================================"
Write-Host "Current version in file: $CurrentVersion" -ForegroundColor Yellow
Write-Host "========================================"

# Calculate suggested version by incrementing the build number from the file
$Parts = $CurrentVersion.Split('.')
$CurMajor   = if ($Parts.Length -gt 0) { $Parts[0] } else { "1" }
$CurMinor   = if ($Parts.Length -gt 1) { $Parts[1] } else { "0" }
$CurRelease = if ($Parts.Length -gt 2) { $Parts[2] } else { "0" }
$CurBuild   = if ($Parts.Length -gt 3) { [int]$Parts[3] + 1 } else { "1" }

$SuggestedVersion = "$CurMajor.$CurMinor.$CurRelease.$CurBuild"

# Prompt user for input
$UserInput = Read-Host "Enter the new version number (Press Enter to use suggestion: $SuggestedVersion)"

if (-Not [string]::IsNullOrWhiteSpace($UserInput)) {
    $VersionStr = $UserInput -replace '^v', ''
    $Parts = $VersionStr.Split('.')
    $Major   = if ($Parts.Length -gt 0) { $Parts[0] } else { "1" }
    $Minor   = if ($Parts.Length -gt 1) { $Parts[1] } else { "0" }
    $Release = if ($Parts.Length -gt 2) { $Parts[2] } else { "0" }
    $Build   = if ($Parts.Length -gt 3) { $Parts[3] } else { "0" }
} else {
    $Major = $CurMajor; $Minor = $CurMinor; $Release = $CurRelease; $Build = $CurBuild
}

$FullVersion = "$Major.$Minor.$Release.$Build"

# Update nodes in the file
$nodes = $xml.SelectNodes("//msb:VerInfo_Major", $ns)
if ($nodes) { foreach ($node in $nodes) { $node.InnerText = $Major } }

$nodes = $xml.SelectNodes("//msb:VerInfo_Minor", $ns)
if ($nodes) { foreach ($node in $nodes) { $node.InnerText = $Minor } }

$nodes = $xml.SelectNodes("//msb:VerInfo_Release", $ns)
if ($nodes) { foreach ($node in $nodes) { $node.InnerText = $Release } }

$nodes = $xml.SelectNodes("//msb:VerInfo_Build", $ns)
if ($nodes) { foreach ($node in $nodes) { $node.InnerText = $Build } }

$keyNodes = $xml.SelectNodes("//msb:VerInfo_Keys", $ns)
if ($keyNodes) {
    foreach ($node in $keyNodes) {
        $text = $node.InnerText
        $text = $text -replace 'FileVersion=\d+\.\d+\.\d+\.\d+', "FileVersion=$FullVersion"
        $text = $text -replace 'ProductVersion=\d+\.\d+\.\d+\.\d+', "ProductVersion=$FullVersion"
        $text = $text -replace 'versionCode=\d+', "versionCode=$Build"
        $text = $text -replace 'versionName=\d+\.\d+\.\d+', "versionName=$Major.$Minor.$Release"
        $text = $text -replace 'CFBundleVersion=[\d\.]+', "CFBundleVersion=$FullVersion"
        $text = $text -replace 'CFBundleShortVersionString=[\d\.]+', "CFBundleShortVersionString=$FullVersion"
        $node.InnerText = $text
    }
}

# Save the file
$encoding = New-Object System.Text.UTF8Encoding($true)
$writer = New-Object System.Xml.XmlTextWriter($TargetFile, $encoding)
$writer.Formatting = [System.Xml.Formatting]::None
$xml.Save($writer)
$writer.Close()

Write-Host "Version successfully updated to: $FullVersion" -ForegroundColor Green