" Basic Setup
set encoding=utf-8
set fileencoding=utf-8
set fileformats=unix,dos,mac
set backspace=indent,eol,start
set smartcase
set ttyfast

" Visual Settings
set ruler
set number
set relativenumber
set colorcolumn=80
set wildmenu
set t_Co=256
set guioptions=egmrti
set scrolloff=3
set modeline
set laststatus=2
set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)

"set list
"set listchars=space:·,tab:>-
set background=dark
set termguicolors

if &term =~ '256color'
  set t_ut=
endif

highlight Normal guifg=#c0caf5 guibg=#1a1b26 ctermfg=white ctermbg=black
highlight SpecialKey guifg=#565f89 ctermfg=8
highlight LineNr guifg=#3b4261 ctermfg=8
highlight ColorColumn guibg=#1f2335 ctermbg=0

" C Development Settings
syntax enable
set makeprg=gcc\ -Wall\ -o\ %<\ %
set errorformat=%A%f:%l:%c:%m

" Map leader key
let mapleader="\<C-b>"
nnoremap <Leader>v :Explore<CR>

" Error format for C files
autocmd FileType c setlocal errorformat=%A\ %#%f:%l:%c:%m
autocmd FileType c nmap <buffer> <Leader>cc :make<CR>
autocmd FileType c nmap <buffer> <Leader>cr :copen<CR>
autocmd FileType c nmap <buffer> <Leader>cf :cclose<CR>
