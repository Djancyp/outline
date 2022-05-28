--TODO:
--  * Add icon colors
--  * Add sort options
--  * Add preview mode
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
}

function M.setup(opt)
  M.main_win = nil
  M.main_buf = nil
  M.main_win_width = 50
  M.main_win_height = 20
  M.main_win_style = "minimal"
  M.main_win_relavent = "win"
  M.main_win_border = 'single'
  M.main_col = ui.width / 2 - M.main_win_width / 2
  M.main_row = ui.height / 2 - M.main_win_height / 2


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
        api.nvim_set_hl(0, changed_icon_color, { fg = colors.blue })
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
  local back_win = api.nvim_get_current_win()
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
    M.setKeys(back_win, M.main_buf)
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

function M.close()
  if M.main_win then
    api.nvim_win_close(M.main_win, false)
    api.nvim_buf_delete(M.main_buf, {})
    M.main_win = nil
    M.main_buf = nil
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
  api.nvim_buf_set_keymap(buf, 'n', 'D',
    string.format([[:<C-U>lua require'outline'.close_buffer(%s)<CR>]], buf),
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
      buffer_names[#buffer_names + 1] = string.format("%s %s %s %s", buffer_id, buffer_name, active_buff,buffer_icon)
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
    api.nvim_win_set_buf(win, buffer)
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
end

return M
