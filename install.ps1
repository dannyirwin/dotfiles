# install.ps1 — dotfiles bootstrap for Windows
# Usage: .\install.ps1 [-Profile Coding|Full] [-DryRun] [-SkipSkills]
# Symbolic links require Developer Mode or an elevated PowerShell session.
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
#   .\install.ps1
# Dotfiles: github.com/dannyirwin/dotfiles

param(
  [ValidateSet("Coding", "Full", "Custom")]
  [string]$Profile,
  [switch]$DryRun,
  [switch]$SkipSkills
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$DOTFILES = $PSScriptRoot
$InstallAgentStack = $true

# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────
function Log    { Write-Host "▶  $args" -ForegroundColor Blue }
function Ok     { Write-Host "✔  $args" -ForegroundColor Green }
function Warn   { Write-Host "⚠  $args" -ForegroundColor Yellow }
function Err    { Write-Host "✖  $args" -ForegroundColor Red }

function Resolve-Profile {
  if ($Profile) {
    switch ($Profile) {
      "Coding" { $script:InstallAgentStack = $false }
      "Full" { $script:InstallAgentStack = $true }
      "Custom" {
        $agents = Read-Host "Install agent tooling? (agents, skills) [y/N]"
        $script:InstallAgentStack = $agents -match '^[Yy]$'
      }
    }
  } elseif ([Console]::IsInputRedirected -eq $false) {
    Write-Host ""
    Write-Host "What do you want to install?" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) Coding tools   packages + WezTerm, tmux, nvim, PowerShell profile"
    Write-Host "  2) Full setup     coding tools + agent setup"
    Write-Host "  3) Custom         pick agent tooling separately"
    Write-Host ""
    $choice = Read-Host "Choice [1-3] (default: 2)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "2" }
    switch ($choice) {
      "1" { $script:InstallAgentStack = $false }
      "2" { $script:InstallAgentStack = $true }
      "3" {
        $agents = Read-Host "Install agent tooling? (agents, skills) [y/N]"
        $script:InstallAgentStack = $agents -match '^[Yy]$'
      }
      default {
        Warn "Invalid choice — using full setup"
        $script:InstallAgentStack = $true
      }
    }
  } else {
    $script:InstallAgentStack = $true
  }

  if ($InstallAgentStack) {
    Log "Install profile: full (coding tools + agent setup)"
  } else {
    Log "Install profile: coding (terminal, editor, PowerShell profile)"
  }
}

function Backup-Existing {
  param($Path)
  $backup = "$Path.backup"
  if (Test-Path $backup) {
    $backup = "$Path.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
  }
  if ($DryRun) {
    Write-Host "[dry-run] Move-Item $Path $backup" -ForegroundColor Gray
  } else {
    Move-Item $Path $backup -Force
  }
}

function Ensure-Directory {
  param($Path)
  if (Test-Path $Path) { return }
  if ($DryRun) {
    Write-Host "[dry-run] New-Item -ItemType Directory $Path" -ForegroundColor Gray
  } else {
    New-Item -ItemType Directory -Force $Path | Out-Null
  }
}

# ─────────────────────────────────────────────
#  Symlink helper (requires developer mode or admin)
# ─────────────────────────────────────────────
function Link-File {
  param($Src, $Dst)
  $dir = Split-Path $Dst -Parent
  Ensure-Directory $dir

  if ((Test-Path $Dst) -and !(Get-Item $Dst).LinkType) {
    Warn "Backing up: $Dst"
    Backup-Existing $Dst
  }

  if (Get-Item $Dst -ErrorAction SilentlyContinue | Where-Object { $_.LinkType }) {
    if (!$DryRun) { Remove-Item $Dst }
  }

  if ($DryRun) {
    Write-Host "[dry-run] Link $Dst → $Src" -ForegroundColor Gray
    return
  }

  try {
    New-Item -ItemType SymbolicLink -Path $Dst -Target $Src -Force -ErrorAction Stop | Out-Null
    Ok "Linked: $Dst"
  } catch {
    Warn "Could not link $Dst — enable Developer Mode or run as admin ($($_.Exception.Message))"
  }
}

# ─────────────────────────────────────────────
#  Winget packages
# ─────────────────────────────────────────────
function Install-Packages {
  Log "Installing packages via winget..."
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Warn "winget not found — skipping package install"
    return
  }
  $packages = @(
    "Starship.Starship",
    "junegunn.fzf",
    "BurntSushi.ripgrep.MSVC",
    "ajeetdsouza.zoxide",
    "sharkdp.fd",
    "Git.Git",
    "Neovim.Neovim",
    "arndawg.tmux-windows"
  )
  foreach ($pkg in $packages) {
    if ($DryRun) {
      Write-Host "[dry-run] winget install --id $pkg --silent --accept-source-agreements --accept-package-agreements" -ForegroundColor Gray
      continue
    }
    winget install --id $pkg --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
      Ok "Installed: $pkg"
    } else {
      Warn "Skipped $pkg (winget exit $LASTEXITCODE)"
    }
  }
}

# ─────────────────────────────────────────────
#  WezTerm config
# ─────────────────────────────────────────────
function Link-WezTerm {
  Log "Linking WezTerm config..."
  # WezTerm on Windows reads %USERPROFILE%\.config\wezterm\wezterm.lua
  Link-File "$DOTFILES\wezterm\wezterm.lua" `
            "$env:USERPROFILE\.config\wezterm\wezterm.lua"
}

# ─────────────────────────────────────────────
#  tmux config
# ─────────────────────────────────────────────
function Link-Tmux {
  Log "Linking tmux config..."
  Link-File "$DOTFILES\tmux\tmux.conf" `
            "$env:USERPROFILE\.tmux.conf"
}

# ─────────────────────────────────────────────
#  Starship config
# ─────────────────────────────────────────────
function Link-Starship {
  Log "Linking Starship config..."
  # Starship on Windows reads %USERPROFILE%\.config\starship.toml
  Link-File "$DOTFILES\zsh\starship.toml" `
            "$env:USERPROFILE\.config\starship.toml"
}

# ─────────────────────────────────────────────
#  Neovim config
# ─────────────────────────────────────────────
function Link-Nvim {
  Log "Linking Neovim config..."
  $dst = "$env:USERPROFILE\.config\nvim"
  $dir = Split-Path $dst -Parent
  Ensure-Directory $dir

  if ((Test-Path $dst) -and !(Get-Item $dst).LinkType) {
    Warn "Backing up: $dst"
    Backup-Existing $dst
  }

  if (Get-Item $dst -ErrorAction SilentlyContinue | Where-Object { $_.LinkType }) {
    if (!$DryRun) { Remove-Item $dst }
  }

  if ($DryRun) {
    Write-Host "[dry-run] Link $dst → $DOTFILES\nvim" -ForegroundColor Gray
    return
  }

  try {
    New-Item -ItemType SymbolicLink -Path $dst -Target "$DOTFILES\nvim" -Force -ErrorAction Stop | Out-Null
    Ok "Linked: $dst"
  } catch {
    Warn "Could not link $dst — enable Developer Mode or run as admin ($($_.Exception.Message))"
  }
}

# ─────────────────────────────────────────────
#  PowerShell profile (adds starship + zoxide init)
# ─────────────────────────────────────────────
function Setup-PSProfile {
  Log "Setting up PowerShell profile..."
  $profileDir = Split-Path $PROFILE -Parent
  Ensure-Directory $profileDir

  $snippet = @"

# ── Dotfiles ────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
  Invoke-Expression (&starship init powershell)
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
# Aliases
Set-Alias -Name v  -Value nvim   -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name vi -Value nvim   -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name g  -Value git    -Option AllScope -ErrorAction SilentlyContinue
function gs  { git status -sb }
function gp  { git push }
function gpl { git pull }
function gl  { git log --oneline --graph --decorate -20 }
# ────────────────────────────────────────────
"@

  if ($DryRun) {
    Write-Host "[dry-run] Would append dotfiles block to $PROFILE" -ForegroundColor Gray
    return
  }

  if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Force $PROFILE | Out-Null }

  if (!(Select-String -Path $PROFILE -Pattern "── Dotfiles ──" -Quiet)) {
    Add-Content $PROFILE $snippet
    Ok "PowerShell profile updated: $PROFILE"
  } else {
    Warn "Dotfiles block already in PowerShell profile — skipping."
  }
}

# ─────────────────────────────────────────────
#  Agent instructions
# ─────────────────────────────────────────────
function Link-Agents {
  Log "Linking agent instructions..."

  $agentsMd = Join-Path $DOTFILES "AGENTS.md"
  if ((Test-Path $agentsMd) -and !(Get-Item $agentsMd).LinkType) {
    Warn "Backing up: $agentsMd"
    Backup-Existing $agentsMd
  }
  if (Get-Item $agentsMd -ErrorAction SilentlyContinue | Where-Object { $_.LinkType }) {
    if (!$DryRun) { Remove-Item $agentsMd -Force }
  }
  if ($DryRun) {
    Write-Host "[dry-run] (cd $DOTFILES && link AGENTS.md .agents\AGENTS.md)" -ForegroundColor Gray
  } else {
    Push-Location $DOTFILES
    try {
      New-Item -ItemType SymbolicLink -Path "AGENTS.md" -Target ".agents\AGENTS.md" -Force -ErrorAction Stop | Out-Null
      Ok "Linked: $agentsMd → .agents\AGENTS.md"
    } catch {
      Warn "Could not link repo-root AGENTS.md ($($_.Exception.Message))"
    } finally {
      Pop-Location
    }
  }

  $agentsDst = "$env:USERPROFILE\.agents"
  $agentsDir = Split-Path $agentsDst -Parent
  Ensure-Directory $agentsDir

  if ((Test-Path $agentsDst) -and !(Get-Item $agentsDst).LinkType) {
    Warn "Backing up: $agentsDst"
    Backup-Existing $agentsDst
  }

  if (Get-Item $agentsDst -ErrorAction SilentlyContinue | Where-Object { $_.LinkType }) {
    if (!$DryRun) { Remove-Item $agentsDst }
  }

  if ($DryRun) {
    Write-Host "[dry-run] Link $agentsDst → $DOTFILES\.agents" -ForegroundColor Gray
    Link-File "$DOTFILES\.agents\AGENTS.md" `
              "$env:USERPROFILE\.claude\CLAUDE.md"
    return
  }

  try {
    New-Item -ItemType SymbolicLink -Path $agentsDst -Target "$DOTFILES\.agents" -Force -ErrorAction Stop | Out-Null
    Ok "Linked: $agentsDst"
  } catch {
    Warn "Could not link $agentsDst — enable Developer Mode or run as admin ($($_.Exception.Message))"
  }

  Link-File "$DOTFILES\.agents\AGENTS.md" `
            "$env:USERPROFILE\.claude\CLAUDE.md"
}

# ─────────────────────────────────────────────
#  Agent skills (via npx skills)
# ─────────────────────────────────────────────
function Install-Skills {
  if ($SkipSkills) {
    Warn "Skipping skills install (-SkipSkills)"
    return
  }

  if (!(Test-Path "$DOTFILES\skills-lock.json")) {
    Log "No skills-lock.json found — skipping skills install"
    return
  }

  if (!(Get-Command npx -ErrorAction SilentlyContinue)) {
    Warn "npx not found — skipping skills install (install Node.js to enable)"
    return
  }

  Log "Installing agent skills from skills-lock.json..."

  if ($DryRun) {
    Write-Host "[dry-run] npx skills experimental_install" -ForegroundColor Gray
    return
  }

  Push-Location $DOTFILES
  try {
    npx --yes skills experimental_install
    if ($LASTEXITCODE -eq 0) {
      Ok "Skills installed from skills-lock.json"
    } else {
      Warn "Skills install failed — continuing (run 'npx skills experimental_install' in $DOTFILES manually)"
    }
  } finally {
    Pop-Location
  }
}

# ─────────────────────────────────────────────
#  Run
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "  DOTFILES — Windows installer" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) { Warn "Dry-run mode — no changes will be made." }

Resolve-Profile

Install-Packages
Link-WezTerm
Link-Tmux
Link-Starship
Link-Nvim
Setup-PSProfile

if ($InstallAgentStack) {
  Link-Agents
  Install-Skills
}

Write-Host ""
Ok "All done! Restart WezTerm to see changes."
Write-Host ""
Write-Host "  Optional next steps:" -ForegroundColor Cyan
Write-Host "  • Install JetBrains Mono: https://www.jetbrains.com/legalnotices/font/"
Write-Host "  • Dot-source `$HOME\dotfiles\local.ps1` from your profile for machine-specific config (not tracked)"
Write-Host ""
