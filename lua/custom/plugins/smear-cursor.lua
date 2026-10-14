-- smear-cursor
vim.pack.add {
  'https://github.com/sphamba/smear-cursor.nvim',
}

require('smear_cursor').setup {
  stiffness = 0.8,
  trailing_stiffness = 0.5,
  distance_stop_animating = 0.5,
  smear_insert_mode = false,
}
