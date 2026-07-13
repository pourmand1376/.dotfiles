return {
  {
    "folke/snacks.nvim",
    opts = {
      -- let yazi handle opening directories instead of the snacks explorer
      explorer = { replace_netrw = false },
      picker = {
        sources = {
          explorer = {
            enabled = false,
            hidden = true,
            ignored = false,
          },
          files = {
            hidden = true,
            ignored = false,
          },
        },
      },
    },
  },
}
