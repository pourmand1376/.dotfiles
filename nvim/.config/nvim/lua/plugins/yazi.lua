-- ~/.config/nvim/lua/plugins/yazi.lua
return {
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    keys = {
      {
        "<leader>-",
        "<cmd>Yazi<cr>",
        desc = "Open yazi at current file",
      },
      {
        "<leader>cw",
        "<cmd>Yazi cwd<cr>",
        desc = "Open yazi in cwd",
      },
      {
        "<C-Up>",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume yazi",
      },
    },
    opts = {
      open_for_directories = false,
    },
  },
}
