# Default profile

# ========================== ENV Variables ====================================
# =============================================================================

function Configure-EnvironmentPath {
    [string[]]$PathsToAdd = @(
        "C:\scripts" # scripts
    )

    $EnvPath = [System.Environment]::GetEnvironmentVariable('PATH')
    $EnvPathVarsArr = $EnvPath -split ';'
    $EnvPathVarsArrFiltered = foreach ($var in $PathsToAdd) {
        $EnvPathVarsArr | Where-Object {
            if (!(Test-Path $_)) {
                Write-Host "path: '$_' is undefined" -ForegroundColor Red -NoNewline
            }
            elseif (!(Test-Path $_ -IsValid)) {
                Write-Host "Path is valid, but does not include any data" -ForegroundColor Yellow
            }
            elseif (Test-Path $_) {
                Write-Verbose "File exists"
                $pattern = "^$([regex]::Escape($var))\\?"
                $_ -notMatch $pattern -and $_ -ne ''
            }
        }
    }
    $EnvPathVarsArrFiltered += $PathsToAdd
    $EnvPath = $EnvPathVarsArrFiltered -join ';'
    Write-Verbose "Updating ENV:PATH to: $EnvPath"
    [System.Environment]::SetEnvironmentVariable('PATH', $EnvPath)
}

# ============================= Modules =======================================
# =============================================================================
# Install-Module -Name Pester

# =============================== Global Variables ============================
# =============================================================================

# ------------------- config for running profile (Sourcing) -------------------
$LogLevel = "info" # silent, error, debug, info, verbose                   #
$Version = "1.0.0"                                                            #
# -----------------------------------------------------------------------------

# Find out if the current user identity is elevated (has admin rights)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$ExecutionPolicy = Get-ExecutionPolicy

$adminUPN = "lazyadmin@lazydev.onmicrosoft.com"
$sharepointAdminUrl = "https://lazydev-admin.sharepoint.com"

# ------------------- git -------------------------
$RepoDefaultPath = "C:\Users\970827\source\repos" #
$GitEmail = (git config --global user.email)      #
$GitName = (git config --global user.name)        #
# -------------------------------------------------

# ========================== Global Functions =================================
# =============================================================================

# Make it easy to edit this profile once it's installed
function Edit-Profile {
    if ($host.Name -match "ise") {
        $psISE.CurrentPowerShellTab.Files.Add($profile.CurrentUserAllHosts)
    }
    else {
        code $profile.CurrentUserAllHosts
    }
}

function New-File {
    [cmdletbinding()]
    param(
        [parameter(Position = 0, Mandatory = $False)]
        [string]$Path
    )
    if (!(Test-Path -Path $Path -IsValid)) {
        Write-Host "Invalid path: $path" -ForegroundColor Red
        exit 1
    } 
    else {
        Write-Verbose "valid path: $path" -ForegroundColor Red
    }    

    # valid paths
    if (Test-Path -Path $Path) {
        Write-Host "Exists already: $path" -ForegroundColor Red
        exit 1
    }  
    else {
        Write-Verbose "Creating new file '$Name'"
        New-Item -ItemType File -Name $Path -Path $PWD -Force | Out-Null
    }
}

# =============================== Global Aliases ==============================
# =============================================================================

# UNIX-like aliases
Set-Alias -Name Touch -Value New-File
Set-Alias -Name Sudo -Value Run-AsAdmin 

# =============================== Setup Commands ==============================
# =============================================================================
# - run any other top level config commands here

function Configure-ShellStyle {

    # If so and the current host is a command line, then change to red color 
    # as warning to user that they are operating in an elevated context
    if (($host.Name -match "ConsoleHost")) {

        # Style default PowerShell Console
        $shell = $Host.UI.RawUI
        $shell.BackgroundColor = "Black"
        $shell.ForegroundColor = "White"
        
        $hostversion = "$($Host.Version.Major)`.$($Host.Version.Minor)"
        $shell.WindowTitle = "Scott PowerShell $hostversion"

        # If so and the current host is a command line, then change to red color 
        # as warning to user that they are operating in an elevated context
        if ($isAdmin) {
            $shell.BackgroundColor = "DarkRed"
            $host.PrivateData.ErrorBackgroundColor = "White"
            $host.PrivateData.ErrorForegroundColor = "DarkRed"
        }
    }

    Set-PSReadlineOption -Color @{
        "Command"   = [ConsoleColor]::Green
        "Parameter" = [ConsoleColor]::Gray
        "Operator"  = [ConsoleColor]::Magenta
        "Variable"  = [ConsoleColor]::White
        "String"    = [ConsoleColor]::Yellow
        "Number"    = [ConsoleColor]::Blue
        "Type"      = [ConsoleColor]::Cyan
        "Comment"   = [ConsoleColor]::DarkCyan
    } 
}

Write-Host "Operating system: $($computerInfo.OsArchitecture) $($computerInfo.OsName) version $($computerInfo.OsVersion)" -ForegroundColor Cyan
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan

Configure-EnvironmentPath
Configure-ShellStyle

# Set Default location
# Set-Location D:\SysAdmin\scripts
 
# Delete temporary variables to prevent cluttering up the user profile. 
Remove-Variable identity # to get to $isAdmin
Remove-Variable principal # to get to $isAdmin

# Handle Reporting of this run
switch ($LogLevel.ToLower()) {
    "silent" {
        break
    }

    "verbose" {
        Write-Host "$(Get-Date) | Verbose | Sourced script: $PSCommandPath" -ForegroundColor Yellow
        Write-Host ("=" * 20 + $PSCommandPath.ToString() + "=" * 20) -ForegroundColor DarkBlue
        Get-Content $PSCommandPath | Write-Host -ForegroundColor DarkBlue
        break
    }

    "info" {
        Write-Host "$(Get-Date) | INFO | Sourcing script: $PSCommandPath" -ForegroundColor DarkGray
        break
    }

    default {
        Write-Host "Invalid LogLevel: $LogLevel @ $PSCommandPath" -ForegroundColor Red
        exit 1
    }
}

[PSCustomObject]@{
    ProfileName = 'Default'
}
