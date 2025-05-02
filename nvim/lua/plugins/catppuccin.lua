return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      -- load the color scheme here
      vim.cmd("[[colorscheme catppuccin]]")
    end,
  },
}
