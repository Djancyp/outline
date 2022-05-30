# Outline ( Another Nvim Buffer Management with Winbar )

Outline is a simple(not so simple) Nvim buffer management plugin written in Lua.
 ![](https://github.com/Djancyp/outline/blob/main/images/outline.gif)
# What you will get with this plugin. 

- Uses Nvim winbar to show buffer name and file change indicator.
// image 
- Buffer management ui.
  - Buffer switch.
  ![Buffer main](/images/outline-main.png)
  - Buffer status.
  ![Status line](/images/winbar.png)
  - Buffer close.
  - Buffer Preview.
  ![Previw](/images/preview.png)
  - Buffer bind shortcut key.
  ![Key binding](/images/bind.png)

## requirements
- Neovim Nightly ≥ v0.8 - Winbar support
- A patched [nerd font](https://www.nerdfonts.com/) for the buffer icons
- [nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons) for filetype icons (recommended)
## Install

```lua
use {"Djancyp/outline"}

require('outline').setup()
```

## Usage

```lua
// Toggle  Buffer tab
:BSOpen
// Recommended key binding shift+c
<S-c>
```
## Keys
```
| Key            | Action                          |
| -------------- | ------------------------------- |
| q,ESC,Ctrl-c   | exit outline window             |
| j or <Tab>     | navigate down                   |
| k or <S-Tab>   | navigate up                     |
| D              | close buffer                    |
| `<CR>`         | jump to buffer                  |
| s              | open buffer in horizontal split |
| v              | open buffer in vertical split   |
| <S-P>          | open preview for buffer         |
| <S-B>          | bind buffer to a key            |
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate. 
## License
[MIT](https://choosealicense.com/licenses/mit/)
