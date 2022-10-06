set noautoread
set relativenumber
set nowrap
if exists ('termguicolors')
  let &t_8f =  "\<Esc>[38:2:%lu:%lu:%lum"
  let &t_8b =  "\<Esc>[48:2:%lu:%lu:%lum"
  set t_Co=256
  set termguicolors
endif
set icon
set ruler
set nomore
set showmatch
set ignorecase
set mouse=v
set hlsearch
set tabstop=4
set softtabstop=4
set expandtab
set shiftwidth=4
set autoindent
set number
set modeline
set textwidth=78
set shiftround
set hidden
set smartcase
set mouse=a
set ttyfast
set spell
set noswapfile
syntax on
filetype plugin indent on
colorscheme darkblue
