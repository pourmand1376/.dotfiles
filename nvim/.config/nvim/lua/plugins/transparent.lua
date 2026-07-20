-- Make Neovim's background transparent so the terminal (WezTerm) shows through.
return {
  -- Enable native transparency for tokyonight (LazyVim's default colorscheme).
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },

  -- Colorscheme-agnostic fallback: clear background highlight groups after any
  -- colorscheme loads, so transparency works even if you switch themes.
  {
    "LazyVim/LazyVim",
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("transparent_bg", { clear = true }),
        callback = function()
          local groups = {
            "Normal",
            "NormalNC",
            "NormalFloat",
            "FloatBorder",
            "SignColumn",
            "LineNr",
            "EndOfBuffer",
            "MsgArea",
            "TabLine",
            "TabLineFill",
            "StatusLine",
            "StatusLineNC",
          }
          for _, g in ipairs(groups) do
            vim.api.nvim_set_hl(0, g, { bg = "none" })
          end
        end,
      })
    end,
  },
}
