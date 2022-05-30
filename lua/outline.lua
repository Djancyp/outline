--TODO:
--  * Add icon colors
--  * Add sort options
--  * Add Options for configuring the outline
local api = vim.api
local cmd = vim.api.nvim_create_autocmd
local ui = api.nvim_list_uis()[1]
require 'split'
local M = {}

local colors = {
  green = "#66EB73",
  red = "#E16071",
  blue = "#649CD9",
  yellow = "#F2AC42",
  grey = "#868B8E",
}

function M.setup(opt)
  M.main_win = nil
  M.main_buf = nil
  M.main_win_width = 50
  M.main_win_height = 20
  M.main_win_style = "minimal"
  M.main_win_relavent = "win"
  M.main_win_border = 'double'
  M.main_col = ui.width / 2 - M.main_win_width / 2
  M.main_row = ui.height / 2 - M.main_win_height / 2

  -- Preview mode window
  M.preview_win = nil
  M.preview_buf = nil
  M.preview_win_width = ui.width / 2
  M.preview_win_height = ui.height / 2
  M.preview_win_style = "minimal"
  M.preview_win_relavent = "win"
  M.preview_win_border = 'double'
  M.preview_col = M.main_win_width / 2 - M.preview_win_width / 2
  M.preview_row = M.main_win_height / 2 - M.preview_win_height / 2
  M.custom_keys = {}

  local ignore_filetypes = {
    "telescope",
    "packer",
    "dashboard",
    "help",
    "neo-tree",
    "toggleterm"
  }
  cmd({ "CursorMoved", "CursorMovedI", "BufWinEnter", "BufFilePost" }, {
    callback = function()
      vim.cmd("setlocal winbar=" .. "")
      if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
        return
      end
      local current_buffer = api.nvim_get_current_buf()
      local current_buffer_name = api.nvim_buf_get_name(current_buffer)
      if current_buffer_name ~= "" then
        local extension = vim.fn.fnamemodify(current_buffer_name, ":e")
        local file_icon, file_icon_color = require('nvim-web-devicons').get_icon_color(current_buffer_name, extension, { default = default })
        if file_icon == nil then
          file_icon = '~'
        end
        local iconColor = 'FileIconColor' .. extension
        api.nvim_set_hl(0, iconColor, { fg = file_icon_color })

        local changed_icon_color = "FileIconColor"
        local changed_icon = ""
        api.nvim_set_hl(0, changed_icon_color, { fg = colors.grey })
        if vim.bo.modified then
          api.nvim_set_hl(0, changed_icon_color, { fg = colors.green })
        end
        -- lua empty caracter reqexp
        api.nvim_buf_set_var(current_buffer, current_buffer_name .. 'winbar', current_buffer_name)
        local text = "%#" .. iconColor .. "#" .. file_icon .. "" .. "%*" .. "\\ %f%=" .. "%#" .. changed_icon_color .. "#" .. changed_icon .. "%*" .. "\\ "
        vim.cmd("setlocal winbar=" .. "\\ " .. text)
      end
    end
  })
end

function M.open()
  M.back_win = api.nvim_get_current_win()
  if not M.main_buf and not M.main_win then
    M.main_buf = api.nvim_create_buf(false, true)
    M.main_win = api.nvim_open_win(M.main_buf, false, {
      relative = M.main_win_relavent,
      width = M.main_win_width,
      height = M.main_win_height,
      style = M.main_win_style,
      row = M.main_row,
      col = M.main_col,
      anchor = 'NW',
      border = M.main_win_border
    })
    M.build_win()
    M.setKeys(M.back_win, M.main_buf)
    M.add_custom_keys()
  else
    xpcall(function()
      api.nvim_win_close(M.main_win, false)
      api.nvim_buf_delete(M.main_buf, {})
      M.main_win = nil
      M.main_buf = nil
    end, function()
      M.main_win = nil
      M.main_buf = nil
      M.open()
    end)
  end
end

function M.add_custom_keys()
  for k, v in pairs(M.custom_keys) do
    api.nvim_buf_set_keymap(M.main_buf, 'n', v.key,
      string.format([[:<C-U>lua require'outline'.set_saved_buffer(%s,%s)<CR>]], M.back_win, tonumber(v.buffer)),
      { nowait = true, noremap = true, silent = true })
  end
end

function M.set_saved_buffer(win, buf)
  api.nvim_win_set_buf(win, tonumber(buf))
  M.close()
end

function M.openPreview(buf)
  M.preview_buf = api.nvim_create_buf(false, true)
  -- rount float to int
  M.preview_win_width = math.floor(M.preview_win_width)
  M.preview_win_height = math.floor(M.preview_win_height)
  M.preview_win = api.nvim_open_win(M.preview_buf, false, {
    relative = M.preview_win_relavent,
    width = M.preview_win_width,
    height = M.preview_win_height,
    style = M.preview_win_style,
    row = M.preview_row,
    col = M.preview_col,
    anchor = 'NW',
    border = M.preview_win_border
  })
  local cursor_pos = api.nvim_win_get_cursor(M.main_win)
  cursor_pos[1] = cursor_pos[1] - 1
  local lines = api.nvim_buf_get_lines(buf, cursor_pos[1], -1, false)[1]
  local buffer = tonumber(lines:split(" ")[1])
  api.nvim_win_set_buf(M.preview_win, buffer)
  api.nvim_set_current_win(M.preview_win)
  -- not modifiable
  api.nvim_buf_set_option(M.preview_buf, 'modifiable', false)
  -- attach key to quit preview
  M.setPreviewKeys(M.preview_buf)
end

function M.setPreviewKeys(buf)
  api.nvim_buf_set_keymap(0, 'n', 'q', ':lua require"outline".close_preview()<CR>',
    { nowait = true, noremap = true, silent = true })
end

function M.close_preview()
  api.nvim_win_close(M.preview_win, false)
  api.nvim_buf_delete(M.preview_buf, {})
  M.preview_win = nil
  M.preview_buf = nil
  api.nvim_set_current_win(M.main_win)
end

function M.close()
  if M.main_win then
    api.nvim_win_close(M.main_win, false)
    api.nvim_buf_delete(M.main_buf, {})
    M.main_win = nil
    M.main_buf = nil
    if M.preview_buf ~= nil then
      M.close_preview()
    end
  end
end

function M.setKeys(win, buf)
  -- Basic window buffer configuration
  api.nvim_buf_set_keymap(buf, 'n', '<CR>',
    string.format([[:<C-U>lua require'outline'.set_buffer(%s,%s, 'window', vim.v.count)<CR>]], win, buf),
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'n', 's',
    string.format([[:<C-U>lua require'outline'.set_buffer(%s,%s, 'hsplit', vim.v.count)<CR>]], win, buf),
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'n', 'v',
    string.format([[:<C-U>lua require'outline'.set_buffer(%s,%s, 'vsplit', vim.v.count)<CR>]], win, buf),
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'n', 'P',
    string.format([[:<C-U>lua require'outline'.openPreview(%s)<CR>]], buf),
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'n', 'D',
    string.format([[:<C-U>lua require'outline'.close_buffer(%s)<CR>]], buf),
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'n', 'B',
    string.format([[:<C-U>lua require'outline'.open_input_window(%s)<CR>]], buf),
    { nowait = true, noremap = true, silent = true })
  -- Navigation keymaps
  api.nvim_buf_set_keymap(buf, 'n', 'q', ':lua require"outline".close()<CR>',
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':lua require"outline".close()<CR>',
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'n', '<Tab>', 'j',
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'n', '<S-Tab>', 'k',
    { nowait = true, noremap = true, silent = true })
  vim.cmd(string.format("au CursorMoved <buffer=%s> if line(\".\") == 1 | call feedkeys('j', 'n') | endif", buf))
end

function M.build_win()
  local empty = {}
  empty[#empty + 1] = string.rep(" ", M.main_win_width)

  api.nvim_buf_set_option(M.main_buf, "modifiable", true)
  api.nvim_buf_set_lines(M.main_buf, 0, -1, false, empty)
  M.list_buffers()
  local menu = 'Buffers:'
  -- api.nvim_buf_set_lines(M.main_buf, 0, 1, false, { menu })
  api.nvim_buf_set_text(M.main_buf, 0, 1, 0, menu:len() + 1, { menu })
  api.nvim_buf_add_highlight(M.main_buf, -1, 'Folded', 0, 0, -1)
  api.nvim_buf_set_option(M.main_buf, "modifiable", false)
end

function M.list_buffers()
  --get open buffe
  local buffers = api.nvim_list_bufs()
  local buffer_names = {}
  table.sort(buffers)
  local current_buffer = api.nvim_get_current_buf()
  for _, buffer in ipairs(buffers) do
    --check if buffers are avtive
    if api.nvim_buf_is_loaded(buffer) then
      local buffer_name = api.nvim_buf_get_name(buffer)
      -- check if buffer has changed
      if buffer_name == "" or nil then goto continue end

      local buffer_changed = api.nvim_buf_get_option(buffer, 'modified')
      local buffer_id = api.nvim_buf_get_number(buffer)

      local active_buff = ""
      if buffer_id == current_buffer then
        active_buff = ""
      end
      local buffer_icon = buffer_changed and '﨣' or ''

      local max_width = M.main_win_width - #buffer_name - 20
      local buffer_name_width = string.len(buffer_name)
      if buffer_name_width > max_width then
        buffer_name = "..." .. string.sub(buffer_name, 1 - max_width)
      end
      for b, bind in pairs(M.custom_keys) do
        if bind.buffer == buffer_id then
          buffer_name = string.format("%s %s", bind.key .. " ", buffer_name)
        end
      end
      buffer_names[#buffer_names + 1] = string.format("%s %s %s %s", buffer_id, buffer_name, active_buff, buffer_icon)
      ::continue::
    end
  end
  api.nvim_set_current_win(M.main_win)
  if #buffer_names ~= 0 then
    api.nvim_buf_set_lines(M.main_buf, 2, #(buffer_names), false, buffer_names)
  end
end

function M.set_buffer(win, buf, opt)
  local cursor_pos = api.nvim_win_get_cursor(M.main_win)
  cursor_pos[1] = cursor_pos[1] - 1
  local lines = api.nvim_buf_get_lines(buf, cursor_pos[1], -1, false)[1]
  local buffer = tonumber(lines:split(" ")[1])
  --check if window is split
  if opt == 'window' then
    api.nvim_win_set_buf(win, tonumber(buffer))
  elseif opt == 'hsplit' then
    api.nvim_command('vsplit')
    api.nvim_win_set_buf(api.nvim_get_current_win(), buffer)
  elseif opt == 'vsplit' then
    api.nvim_command('split')
    api.nvim_win_set_buf(api.nvim_get_current_win(), buffer)
  end
  M.close()
end

function M.close_buffer(buf)
  local cursor_pos = api.nvim_win_get_cursor(M.main_win)
  local lines = api.nvim_buf_get_lines(buf, cursor_pos[1] - 1, -1, false)[1]
  local buffer = tonumber(lines:split(' ')[1])
  -- close buffer
  vim.cmd(string.format('bd %s', buffer))
  -- reset the buffer loader
  M.close()
  M.open()
end

function M.open_input_window()
  M.input_buf = api.nvim_create_buf(false, true)
  M.input_win = api.nvim_open_win(M.input_buf, false, {
    relative = 'editor',
    width = 10,
    height = 1,
    row = ui.height / 2 - 1,
    col = ui.width / 2 - 10 / 2,
    style = 'minimal',
    border = "single"
  })
  M.set_input_keys(M.input_buf)
  -- turn off lsp for this buffer
  api.nvim_buf_set_option(M.input_buf, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  api.nvim_win_set_option(M.input_win, 'cursorline', true)
  api.nvim_set_current_win(M.input_win)
  api.nvim_win_set_cursor(M.input_win, { 1, 0 })
  api.nvim_command('startinsert')
  api.nvim_buf_set_option(M.input_buf, 'modifiable', true)
end

function M.set_input_keys(buf)

  api.nvim_buf_set_keymap(buf, 'i', '<CR>', '<Esc>:lua require"outline".bind_key_to_buffer()<CR>',
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'i', '<C-c>', '<Esc>:lua require"outline".close_input_window()<CR>',
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'i', 'q', '<Esc>:lua require"outline".close_input_window()<CR>',
    { nowait = true, noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, 'i', '<Esc>', '<Esc>:lua require"outline".close_input_window()<CR>',
    { nowait = true, noremap = true, silent = true })
end

function M.close_input_window()
  api.nvim_win_close(M.input_win, true)
  M.input_buf = nil
  M.input_win = nil
end

function M.bind_key_to_buffer()
  --get current line from window
  local main_cursor_pos = api.nvim_win_get_cursor(M.main_win)
  main_cursor_pos[1] = main_cursor_pos[1] - 1
  local lines = api.nvim_buf_get_lines(M.main_buf, main_cursor_pos[1], -1, false)[1]
  local buffer = tonumber(lines:split(" ")[1])
  local cursor_pos = api.nvim_win_get_cursor(M.input_win)
  local key = api.nvim_buf_get_lines(M.input_buf, cursor_pos[1] - 1, -1, false)[1]
  api.nvim_buf_set_keymap(M.main_buf, 'n', key,
    string.format([[:<C-U>lua require'outline'.set_buffer(%s,%s, 'window', vim.v.count)<CR>]], M.back_win, M.main_buf),
    { nowait = true, noremap = true, silent = true })
  -- add to custom keybindings
  --  check if buffer is already in custom keybindings
  --  if not add its
  for _, v in pairs(M.custom_keys) do
    if v.key == key then
      vim.notify('Key already exists')
      api.nvim_command('startinsert')
      return
    else if v.buffer == buffer then
        v.key = key
        vim.notify('Buffer binding changed.')
        M.close_input_window()
        M.close()
        M.open()

        return
      end
    end
  end
  M.custom_keys[#M.custom_keys + 1] = {
    key = key,
    buffer = buffer,
    window = M.back_win,
    opt = 'window'
  }
  M.close_input_window()
  vim.notify('Buffer binding added.')
  M.close()
  M.open()
end

return M
