local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

opt.splitbelow = true
opt.splitright = true

opt.updatetime = 250
opt.timeoutlen = 300
opt.completeopt = "menu,menuone,noselect"

opt.cursorline = true
opt.cursorlineopt = "number"

opt.termguicolors = true
opt.background = "dark"
opt.showmode = false

opt.confirm = true
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false

opt.clipboard = "unnamedplus"

opt.list = true
opt.listchars = {
  tab = "  ",
  trail = "·",
  nbsp = "␣",
}

opt.fillchars = {
  eob = " ",
  fold = " ",
  foldopen = " ",
  foldclose = " ",
  foldsep = " ",
}

opt.wildignore:append({
  "*.o",
  "*.pyc",
  "*.zip",
  "**/node_modules/**",
  "**/.git/**",
})
