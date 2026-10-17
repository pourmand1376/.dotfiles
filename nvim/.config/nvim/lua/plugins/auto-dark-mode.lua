-- Follow macOS light/dark mode, live: polls the system appearance and flips
-- vim.o.background, which makes tokyonight swap moon <-> day on its own.
-- Polling the OS (instead of asking the terminal) also works inside zellij.
return {
  "f-person/auto-dark-mode.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    update_interval = 3000,
  },
}
