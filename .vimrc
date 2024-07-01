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
set colorcolumn=80
set wildmenu
set t_Co=256
set guioptions=egmrti
set background=light
colorscheme default

if &term =~ '256color'
  set t_ut=
endif

autocmd ColorScheme * highlight LineNr ctermfg=gray guifg=gray
autocmd ColorScheme * highlight ColorColumn ctermbg=gray


set scrolloff=3
set modeline
set laststatus=2
set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)"

"*****************************************************************************
" C Development Settings
"*****************************************************************************

syntax enable

set makeprg=gcc\ -Wall\ -o\ %<\ %
set errorformat=%A%f:%l:%c:%m

let mapleader = "\<C-b>"
nnoremap <Leader>v :Explore<CR>

autocmd FileType c setlocal errorformat=%A\ %#%f:%l:%c:%m
autocmd FileType c nmap <buffer> <Leader>cc :make<CR>
autocmd FileType c nmap <buffer> <Leader>cr :copen<CR>
autocmd FileType c nmap <buffer> <Leader>cf :cclose<CR>

