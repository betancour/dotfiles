"*****************************************************************************
" Basic Setup
"*****************************************************************************

set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set ttyfast
set backspace=indent,eol,start
set smartcase
set fileformats=unix,dos,mac

"*****************************************************************************
" Visual Settings
"*****************************************************************************

set ruler
set number
set relativenumber
highlight LineNr ctermfg=gray guifg=gray
highlight ColorColumn ctermbg=gray
set colorcolumn=80
set wildmenu
set t_Co=256
set guioptions=egmrti

if &term =~ '256color'
  set t_ut=
endif

set scrolloff=3
set modeline
set laststatus=2
set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)"
