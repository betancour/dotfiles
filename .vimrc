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
highlight SpecialKey ctermfg=gray guifg=gray

if &term =~ '256color'
  set t_ut=
endif

highlight LineNr ctermfg=gray guifg=gray
highlight ColorColumn ctermbg=gray

" Force background setting to light
autocmd VimEnter * set background=light

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
