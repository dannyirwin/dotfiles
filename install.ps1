# install.ps1 — dotfiles bootstrap for Windows
# Run from an elevated PowerShell window:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
#   .\install.ps1
# Dotfiles: github.com/dannyirwin/dotfiles

param([switch]$DryRun, [switch]$SkipSkills)

$ErrorActionPreference = "Stop"
$DOTFILES = $PSScriptRoot

# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────
function Log    { Write-Host "▶  $args" -ForegroundColor Blue }
function Ok     { Write-Host "✔  $args" -ForegroundColor Green }
function Warn   { Write-Host "⚠  $args" -ForegroundColor Yellow }
function Err    { Write-Host "✖  $args" -ForegroundColor Red }

function Invoke-Cmd {
  if ($DryRun) { Write-Host "[dry-run] $args" -ForegroundColor Gray }
  else { & @args }
}

# ─────────────────────────────────────────────
#  Symlink helper (requires developer mode or admin)
# ─────────────────────────────────────────────
function Link-File {
  param($Src, $Dst)
  $dir = Split-Path $Dst -Parent
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }

  if ((Test-Path $Dst) -and !(Get-Item $Dst).LinkType) {
    Warn "Backing up: $Dst → $Dst.backup"
    if (!$DryRun) { Move-Item $Dst "$Dst.backup" -Force }
  }

  if (Get-Item $Dst -ErrorAction SilentlyContinue | Where-Object { $_.LinkType }) {
    if (!$DryRun) { Remove-Item $Dst }
  }

  if (!$DryRun) {
    New-Item -ItemType SymbolicLink -Path $Dst -Target $Src -Force | Out-Null
  } else {
    Write-Host "[dry-run] Link $Dst → $Src" -ForegroundColor Gray
  }
  Ok "Linked: $Dst"
}

# ─────────────────────────────────────────────
#  Winget packages
# ─────────────────────────────────────────────
function Install-Packages {
  Log "Installing packages via winget..."
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
    Invoke-Cmd winget install --id $pkg --silent --accept-source-agreements --accept-package-agreements
    Ok "Installed: $pkg"
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
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }

  if ((Test-Path $dst) -and !(Get-Item $dst).LinkType) {
    Warn "Backing up: $dst → $dst.backup"
    if (!$DryRun) { Move-Item $dst "$dst.backup" -Force }
  }

  if (Get-Item $dst -ErrorAction SilentlyContinue | Where-Object { $_.LinkType }) {
    if (!$DryRun) { Remove-Item $dst }
  }

  if (!$DryRun) {
    New-Item -ItemType SymbolicLink -Path $dst -Target "$DOTFILES\nvim" -Force | Out-Null
  } else {
    Write-Host "[dry-run] Link $dst → $DOTFILES\nvim" -ForegroundColor Gray
  }
  Ok "Linked: $dst"
}

# ─────────────────────────────────────────────
#  PowerShell profile (adds starship + zoxide init)
# ─────────────────────────────────────────────
function Setup-PSProfile {
  Log "Setting up PowerShell profile..."
  $profileDir = Split-Path $PROFILE -Parent
  if (!(Test-Path $profileDir)) { New-Item -ItemType Directory -Force $profileDir | Out-Null }

  $snippet = @"

# ── Dotfiles ────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
  Invoke-Expression (&starship init powershell)
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
  Set-Alias -Name cd -Value z -Option AllScope -Force
}
# Aliases
Set-Alias -Name v  -Value nvim   -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name vi -Value nvim   -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name g  -Value git
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

  Link-File "$DOTFILES\.agents\AGENTS.md" `
            "$DOTFILES\AGENTS.md"

  $agentsDst = "$env:USERPROFILE\.agents"
  $agentsDir = Split-Path $agentsDst -Parent
  if (!(Test-Path $agentsDir)) { New-Item -ItemType Directory -Force $agentsDir | Out-Null }

  if ((Test-Path $agentsDst) -and !(Get-Item $agentsDst).LinkType) {
    Warn "Backing up: $agentsDst → $agentsDst.backup"
    if (!$DryRun) { Move-Item $agentsDst "$agentsDst.backup" -Force }
  }

  if (Get-Item $agentsDst -ErrorAction SilentlyContinue | Where-Object { $_.LinkType }) {
    if (!$DryRun) { Remove-Item $agentsDst }
  }

  if (!$DryRun) {
    New-Item -ItemType SymbolicLink -Path $agentsDst -Target "$DOTFILES\.agents" -Force | Out-Null
  } else {
    Write-Host "[dry-run] Link $agentsDst → $DOTFILES\.agents" -ForegroundColor Gray
  }
  Ok "Linked: $agentsDst"

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
  } finally {
    Pop-Location
  }
  Ok "Skills installed from skills-lock.json"
}

# ─────────────────────────────────────────────
#  Run
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "  DOTFILES — Windows installer" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) { Warn "Dry-run mode — no changes will be made." }

Install-Packages
Link-WezTerm
Link-Tmux
Link-Starship
Link-Nvim
Link-Agents
Install-Skills
Setup-PSProfile

Write-Host ""
Ok "All done! Restart WezTerm to see changes."
Write-Host ""
Write-Host "  Optional next steps:" -ForegroundColor Cyan
Write-Host "  • Install JetBrains Mono: https://www.jetbrains.com/legalnotices/font/"
Write-Host "  • Add a local.ps1 in this folder for machine-specific config (not tracked)"
Write-Host ""
