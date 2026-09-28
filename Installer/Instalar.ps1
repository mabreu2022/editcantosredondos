<#
.SYNOPSIS
    Instalador PowerShell do TRoundedEdit
    
.DESCRIPTION
    Copia os fontes para a pasta de instalacao e adiciona
    o caminho ao Library Path de todas as versoes do Delphi
    encontradas no registro Windows.
    
.NOTES
    Execute como Administrador para instalar em Arquivos de Programas.
    Pode ser executado como usuario normal (instalara em AppData).
    
    Uso: clique direito no arquivo > "Executar com PowerShell"
    Ou : Set-ExecutionPolicy Bypass -Scope Process; .\Instalar.ps1
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "",
    [switch]$Uninstall
)

# ============================================================
#  Configuracao
# ============================================================
$AppName      = "TRoundedEdit"
$AppVersion   = "2.3"
$AppPublisher = "AntiGravity"
$ScriptDir    = $PSScriptRoot
$SourceRoot   = Split-Path $ScriptDir -Parent

# Caminho padrao de instalacao
if (-not $InstallPath) {
    $InstallPath = Join-Path $env:LOCALAPPDATA "$AppPublisher\$AppName"
}

$DelphiInstallDir  = Join-Path $InstallPath "Delphi"
$LazarusInstallDir = Join-Path $InstallPath "Lazarus"
$EmbarcaderoKey    = "HKCU:\Software\Embarcadero\BDS"
$Platforms         = @("Win32", "Win64")

# ============================================================
#  Cores e helpers
# ============================================================
function Write-Header {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  $AppName v$AppVersion - Instalador"        -ForegroundColor Cyan
    Write-Host "  $AppPublisher"                              -ForegroundColor DarkCyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step($msg) { Write-Host ">> $msg" -ForegroundColor Yellow }
function Write-OK($msg)   { Write-Host "   [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "   [!] $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "   $msg" -ForegroundColor Gray }

# ============================================================
#  Nome amigavel da versao BDS
# ============================================================
function Get-DelphiName([string]$BDSVersion) {
    $map = @{
        "15.0" = "Delphi 10.2 Tokyo"
        "16.0" = "Delphi 10.3 Rio"
        "17.0" = "Delphi 10.4 Sydney"
        "18.0" = "Delphi 11 Alexandria"
        "19.0" = "Delphi 11.1"
        "20.0" = "Delphi 11.2"
        "21.0" = "Delphi 11.3"
        "22.0" = "Delphi 11.x"
        "23.0" = "Delphi 12 Athens"
        "24.0" = "Delphi 13"
        "25.0" = "Delphi 14"
    }
    if ($map.ContainsKey($BDSVersion)) { return $map[$BDSVersion] }
    return "Delphi (BDS $BDSVersion)"
}

# ============================================================
#  Adiciona caminho ao Library Path de uma plataforma
# ============================================================
function Add-ToLibraryPath([string]$BDSVersion, [string]$Platform, [string]$NewPath) {
    $regKey = "$EmbarcaderoKey\$BDSVersion\Library\$Platform"
    if (-not (Test-Path $regKey)) { return $false }

    $current = (Get-ItemProperty -Path $regKey -Name SearchPath -ErrorAction SilentlyContinue).SearchPath
    if (-not $current) { $current = "" }

    if ($current.ToLower().Contains($NewPath.ToLower())) { return $true }  # ja existe

    $sep = if ($current -and $current[-1] -ne ';') { ";" } else { "" }
    Set-ItemProperty -Path $regKey -Name SearchPath -Value "$current$sep$NewPath"
    return $true
}

# ============================================================
#  Remove caminho do Library Path (desinstalacao)
# ============================================================
function Remove-FromLibraryPath([string]$BDSVersion, [string]$Platform, [string]$RemovePath) {
    $regKey = "$EmbarcaderoKey\$BDSVersion\Library\$Platform"
    if (-not (Test-Path $regKey)) { return }

    $current = (Get-ItemProperty -Path $regKey -Name SearchPath -ErrorAction SilentlyContinue).SearchPath
    if (-not $current) { return }

    $lc = $current.ToLower()
    $lr = $RemovePath.ToLower()

    foreach ($pat in @("$lr;", ";$lr", $lr)) {
        $idx = $lc.IndexOf($pat)
        if ($idx -ge 0) {
            $current = $current.Remove($idx, $pat.Length)
            $lc      = $current.ToLower()
        }
    }
    Set-ItemProperty -Path $regKey -Name SearchPath -Value $current
}

# ============================================================
#  INSTALACAO
# ============================================================
function Install-Component {
    Write-Header

    # --- Copia arquivos ---
    Write-Step "Copiando arquivos Delphi VCL..."
    New-Item -ItemType Directory -Force -Path $DelphiInstallDir | Out-Null
    $delphiFiles = @("RoundedEdit.pas", "RoundedEditPkg.dpk", "RoundedEditPkg.dproj")
    foreach ($f in $delphiFiles) {
        $src = Join-Path $SourceRoot $f
        if (Test-Path $src) {
            Copy-Item $src $DelphiInstallDir -Force
            Write-OK $f
        } else {
            Write-Warn "$f nao encontrado em $SourceRoot"
        }
    }

    Write-Step "Copiando arquivos Lazarus LCL..."
    New-Item -ItemType Directory -Force -Path $LazarusInstallDir | Out-Null
    $lazFiles = @("LazarusVersion\RoundedEditLaz.pas", "LazarusVersion\RoundedEditPkgLaz.lpk")
    foreach ($f in $lazFiles) {
        $src = Join-Path $SourceRoot $f
        if (Test-Path $src) {
            Copy-Item $src $LazarusInstallDir -Force
            Write-OK (Split-Path $f -Leaf)
        }
    }

    # --- Atualiza Library Path ---
    Write-Step "Detectando instalacoes do Delphi..."
    $found = @()

    for ($v = 12; $v -le 30; $v++) {
        $bdsVer = "$v.0"
        $bdsKey = "$EmbarcaderoKey\$bdsVer"
        if (-not (Test-Path $bdsKey)) { continue }

        $name = Get-DelphiName $bdsVer
        $updated = $false

        foreach ($plat in $Platforms) {
            if (Add-ToLibraryPath $bdsVer $plat $DelphiInstallDir) {
                $updated = $true
            }
        }

        if ($updated) {
            $found += $name
            Write-OK "$name -> Library Path atualizado"
        }
    }

    # --- Resumo ---
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  Instalacao concluida!" -ForegroundColor Green
    Write-Host ""
    Write-Info "Pasta Delphi : $DelphiInstallDir"
    Write-Info "Pasta Lazarus: $LazarusInstallDir"
    Write-Host ""

    if ($found.Count -gt 0) {
        Write-Host "  Library Path atualizado em $($found.Count) versao(oes) do Delphi." -ForegroundColor Green
        Write-Host ""
        Write-Host "  Proximos passos no Delphi:" -ForegroundColor Yellow
        Write-Host "    1. Abra o arquivo: $DelphiInstallDir\RoundedEditPkg.dproj"
        Write-Host "    2. Clique em Build -> Install"
        Write-Host "    3. O componente aparecera na aba AntiGravity"
    } else {
        Write-Warn "Nenhuma instalacao do Delphi encontrada no registro."
        Write-Host "  Adicione manualmente ao Library Path:" -ForegroundColor Yellow
        Write-Host "    Tools > Options > Language > Delphi > Library > Library path"
        Write-Host "    $DelphiInstallDir"
    }

    Write-Host ""
    Write-Host "  Proximos passos no Lazarus:" -ForegroundColor Yellow
    Write-Host "    1. Package > Open Package File"
    Write-Host "    2. Selecione: $LazarusInstallDir\RoundedEditPkgLaz.lpk"
    Write-Host "    3. Compile > Use > Install"
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""

    Read-Host "Pressione ENTER para fechar"
}

# ============================================================
#  DESINSTALACAO
# ============================================================
function Uninstall-Component {
    Write-Header
    Write-Step "Removendo caminhos do Library Path do Delphi..."

    for ($v = 12; $v -le 30; $v++) {
        $bdsVer = "$v.0"
        if (-not (Test-Path "$EmbarcaderoKey\$bdsVer")) { continue }

        foreach ($plat in $Platforms) {
            Remove-FromLibraryPath $bdsVer $plat $DelphiInstallDir
        }
        Write-OK (Get-DelphiName $bdsVer)
    }

    Write-Step "Removendo arquivos..."
    if (Test-Path $InstallPath) {
        Remove-Item $InstallPath -Recurse -Force
        Write-OK "Pasta removida: $InstallPath"
    }

    Write-Host ""
    Write-Host "  Desinstalacao concluida!" -ForegroundColor Green
    Write-Host ""
    Read-Host "Pressione ENTER para fechar"
}

# ============================================================
#  MAIN
# ============================================================
if ($Uninstall) {
    Uninstall-Component
} else {
    Install-Component
}
