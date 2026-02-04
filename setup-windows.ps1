#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Windows Development Environment Setup - Quick Launcher
.DESCRIPTION
    Unified entry point for Windows setup system
.PARAMETER Preset
    Preset name to load
.PARAMETER Modules
    Comma-separated module IDs
.PARAMETER Execute
    Run installation immediately
.PARAMETER DryRun
    Simulate installation
.PARAMETER NoGui
    Run in CLI mode
.EXAMPLE
    .\setup-windows.ps1
.EXAMPLE
    .\setup-windows.ps1 -Preset fullstack-dev -Execute
.EXAMPLE
    .\setup-windows.ps1 -Modules dev.git,dev.nodejs -DryRun
#>

param(
    [string]$Preset,
    [string]$Modules,
    [switch]$Execute,
    [switch]$DryRun,
    [switch]$NoGui
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SetupScript = Join-Path $ScriptDir "windows-setup.py"

# Check Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Python not found. Please install Python 3.8 or higher." -ForegroundColor Red
    Write-Host "   Download: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

# Build arguments
$args = @()

if ($Preset) {
    $args += "--preset"
    $args += $Preset
}

if ($Modules) {
    $args += "--modules"
    $args += $Modules
}

if ($Execute) {
    $args += "--execute"
}

if ($DryRun) {
    $args += "--dry-run"
}

if ($NoGui) {
    $args += "--no-gui"
}

# Run setup
Set-Location $ScriptDir
if ($args.Count -gt 0) {
    & python $SetupScript @args
} else {
    & python $SetupScript
}
