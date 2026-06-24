-- ~/.config/wezterm/wezterm.lua
-- Dotfiles: github.com/dannyirwin/dotfiles

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ─────────────────────────────────────────────
--  Platform detection
-- ─────────────────────────────────────────────
local is_windows = wezterm.target_triple:find("windows") ~= nil
local is_mac     = wezterm.target_triple:find("apple")   ~= nil

-- ─────────────────────────────────────────────
--  Theme: Tokyo Night
-- ─────────────────────────────────────────────
config.color_scheme = "Tokyo Night"

-- Fine-tune / override specific colors
config.colors = {
  cursor_bg        = "#7aa2f7",
  cursor_border    = "#7aa2f7",
  cursor_fg        = "#1a1b26",
  selection_bg     = "#283457",
  selection_fg     = "none",
  -- Tab bar
  tab_bar = {
    background        = "#15161e",
    active_tab        = { bg_color = "#1a1b26", fg_color = "#7aa2f7", intensity = "Bold" },
    inactive_tab      = { bg_color = "#15161e", fg_color = "#565f89" },
    inactive_tab_hover = { bg_color = "#1e2030", fg_color = "#7aa2f7" },
    new_tab           = { bg_color = "#15161e", fg_color = "#565f89" },
    new_tab_hover     = { bg_color = "#15161e", fg_color = "#7aa2f7" },
  },
}

-- ─────────────────────────────────────────────
--  Font
-- ─────────────────────────────────────────────
config.font = wezterm.font_with_fallback({
  { family = "JetBrains Mono", weight = "Regular" },
  { family = "Cascadia Code",  weight = "Regular" }, -- Windows fallback
  { family = "Fira Code" },
  "monospace",
})
config.font_size             = is_windows and 11 or 13
config.line_height           = 1.2
config.cell_width            = 1.0
config.freetype_load_flags   = "NO_HINTING"

-- ─────────────────────────────────────────────
--  Window & appearance
-- ─────────────────────────────────────────────
config.window_background_opacity    = 0.82
config.macos_window_background_blur = 50
config.window_padding              = { left = 12, right = 12, top = 10, bottom = 8 }
config.initial_cols                = 200
config.initial_rows                = 50

-- Hide title bar, keep resize handles
if is_mac then
  config.window_decorations = "RESIZE"
elseif is_windows then
  config.window_decorations = "RESIZE"
else
  config.window_decorations = "NONE"
end

config.window_close_confirmation   = "NeverPrompt"

-- ─────────────────────────────────────────────
--  Tab bar
-- ─────────────────────────────────────────────
config.use_fancy_tab_bar           = false
config.tab_bar_at_bottom           = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width               = 32
config.show_tab_index_in_tab_bar   = false

-- ─────────────────────────────────────────────
--  Cursor
-- ─────────────────────────────────────────────
config.default_cursor_style        = "BlinkingBar"
config.cursor_blink_rate           = 500
config.cursor_blink_ease_in        = "Constant"
config.cursor_blink_ease_out       = "Constant"

-- ─────────────────────────────────────────────
--  Scrollback
-- ─────────────────────────────────────────────
config.scrollback_lines            = 10000
config.enable_scroll_bar           = false

-- ─────────────────────────────────────────────
--  Shell (platform-specific)
-- ─────────────────────────────────────────────
local function resolve_windows_shell()
  local candidates = {
    { "pwsh.exe", "-NoLogo" },
    { "powershell.exe", "-NoLogo" },
  }
  for _, prog in ipairs(candidates) do
    local ok = wezterm.run_child_process({ "cmd.exe", "/c", "where", prog[1] }, "")
    if ok then
      return prog
    end
  end
  return { "powershell.exe", "-NoLogo" }
end

if is_windows then
  config.default_prog = resolve_windows_shell()
elseif is_mac then
  config.default_prog = { "/bin/zsh", "-l" }
else
  config.default_prog = { "/bin/zsh", "-l" }
end

-- ─────────────────────────────────────────────
--  Key bindings
-- ─────────────────────────────────────────────
local act = wezterm.action
local mod = is_mac and "SUPER" or "CTRL|SHIFT"

config.keys = {
  -- Tabs
  { key = "t",          mods = mod,        action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w",          mods = mod,        action = act.CloseCurrentTab({ confirm = false }) },
  { key = "LeftArrow",  mods = mod,        action = act.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = mod,        action = act.ActivateTabRelative(1) },
  { key = "[",          mods = mod,        action = act.ActivateTabRelative(-1) },
  { key = "]",          mods = mod,        action = act.ActivateTabRelative(1) },

  -- Pane splits
  { key = "d",          mods = mod,        action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "D",          mods = mod,        action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h",          mods = "ALT",      action = act.ActivatePaneDirection("Left") },
  { key = "l",          mods = "ALT",      action = act.ActivatePaneDirection("Right") },
  { key = "k",          mods = "ALT",      action = act.ActivatePaneDirection("Up") },
  { key = "j",          mods = "ALT",      action = act.ActivatePaneDirection("Down") },

  -- Font size
  { key = "=",          mods = mod,        action = act.IncreaseFontSize },
  { key = "-",          mods = mod,        action = act.DecreaseFontSize },
  { key = "0",          mods = mod,        action = act.ResetFontSize },

  -- Copy / paste
  { key = "c",          mods = mod,        action = act.CopyTo("Clipboard") },
  { key = "v",          mods = mod,        action = act.PasteFrom("Clipboard") },

  -- Search
  { key = "f",          mods = mod,        action = act.Search({ CaseSensitiveString = "" }) },

  -- Fullscreen
  { key = "Enter",      mods = mod,        action = act.ToggleFullScreen },
}

-- ─────────────────────────────────────────────
--  Mouse bindings
-- ─────────────────────────────────────────────
config.mouse_bindings = {
  -- Right-click pastes
  {
    event  = { Down = { streak = 1, button = "Right" } },
    mods   = "NONE",
    action = act.PasteFrom("Clipboard"),
  },
}

-- ─────────────────────────────────────────────
--  Misc
-- ─────────────────────────────────────────────
config.audible_bell              = "Disabled"
config.visual_bell               = { fade_in_duration_ms = 75, fade_out_duration_ms = 75, target = "CursorColor" }
config.check_for_updates         = false
config.automatically_reload_config = true

return config
