local function find_files_opts()
  local opts = {
    hidden = true,
    no_ignore = false,
  }

  if vim.fn.executable("fd") == 1 then
    opts.find_command = {
      "fd",
      "--type",
      "f",
      "--hidden",
      "--follow",
      "--exclude",
      ".git",
    }
  end

  return opts
end

return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Telescope",
  keys = {
    {
      "<leader>ff",
      function()
        require("telescope.builtin").find_files(find_files_opts())
      end,
      desc = "Find files",
    },
    {
      "<leader>fr",
      function()
        require("telescope.builtin").oldfiles()
      end,
      desc = "Recent files",
    },
    {
      "<leader>fg",
      function()
        require("telescope.builtin").live_grep()
      end,
      desc = "Live grep",
    },
    {
      "<leader>fb",
      function()
        require("telescope.builtin").buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>fh",
      function()
        require("telescope.builtin").help_tags()
      end,
      desc = "Help tags",
    },
    {
      "<leader><leader>",
      function()
        require("telescope.builtin").find_files(find_files_opts())
      end,
      desc = "Find files",
    },
  },
  opts = {
    defaults = {
      prompt_prefix = "  ",
      selection_caret = "  ",
      path_display = { "truncate" },
      sorting_strategy = "ascending",
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.55,
          results_width = 0.8,
        },
        vertical = {
          mirror = false,
        },
        width = 0.87,
        height = 0.80,
        preview_cutoff = 120,
      },
      file_ignore_patterns = {
        "%.git/",
        "node_modules/",
        "%.cache/",
      },
    },
    pickers = {
      find_files = find_files_opts(),
    },
  },
  config = function(_, opts)
    require("telescope").setup(opts)
  end,
}
