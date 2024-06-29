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
<<<<<<< HEAD
  set t_ut=
=======
set t_ut=
>>>>>>> 5ed4ea1 (added changes to vim for C development)
endif

set scrolloff=3
set modeline
set laststatus=2
set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)"
<<<<<<< HEAD
=======

"*****************************************************************************
" C Development Settings 
"***************************************************************************** 

syntax enable
autocmd FileType c setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4

set makeprg=gcc\ -Wall\ -o\ %<\ % 
set errorformat=%A%f:%l:%c:%m 

autocmd FileType c setlocal errorformat=%A\ %#%f:%l:%c:%m 
autocmd FileType c nmap <buffer> <Leader>cc :make<CR> 
autocmd FileType c nmap <buffer> <Leader>cr :copen<CR> 
autocmd FileType c nmap <buffer> <Leader>cf :cclose<CR> 
>>>>>>> 5ed4ea1 (added changes to vim for C development)
