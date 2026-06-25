local function resolve_fd()
	if vim.fn.executable("fd") == 1 then
		return "fd"
	end
	if vim.fn.executable("fdfind") == 1 then
		return "fdfind"
	end
	local local_fd = vim.fn.expand("~/.local/bin/fd")
	if vim.fn.executable(local_fd) == 1 then
		return local_fd
	end
	return nil
end

local function find_files_opts()
	local opts = {
		hidden = true,
		no_ignore = false,
	}

	local fd = resolve_fd()
	if fd then
		opts.find_command = {
			fd,
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
	},
	config = function(_, opts)
		require("telescope").setup(opts)
		local builtin = require("telescope.builtin")
		local find_files = builtin.find_files
		builtin.find_files = function(telescope_opts, ...)
			return find_files(vim.tbl_deep_extend("force", find_files_opts(), telescope_opts or {}), ...)
		end
	end,
}
