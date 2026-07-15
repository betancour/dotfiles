" vim: set fileencoding=utf-8 tabstop=4 softtabstop=4 shiftwidth=4 :
" VIM configuration for 42school compliant C/C++ development
" Enforces strict Norm standards: 80-char line limit, 4-space indentation

" General Settings
set nocompatible
set encoding=utf-8
set fileencoding=utf-8
set backspace=indent,eol,start
set history=1000
set undolevels=1000
set autoread
set hidden
set modeline
set modelines=5

" Display
set number
set ruler
set showcmd
set showmode
set wildmenu
set wildmode=list:longest
set cmdheight=2
set laststatus=2

" Colors and Syntax
syntax enable
set background=dark
try
	colorscheme desert
catch
endtry

" 42 Norm Compliance: Line length limit
set colorcolumn=80
highlight ColorColumn ctermbg=8

" Indentation (42 Norm: 4 spaces, no tabs)
set autoindent
set smartindent
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround

" Remove trailing whitespace on save (42 Norm requirement)
autocmd BufWritePre * :%s/\s\+$//e

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" Performance
set lazyredraw
set synmaxcol=200
set ttimeoutlen=50

" Swap and Backup
set noswapfile
set nobackup
set nowb

" Mouse Support
if has('mouse')
	set mouse=a
endif

" C/C++ Specific (42 Norm compliant)
set cindent
set cinkeys=0{,0},0),:,!^F,o,O,e
set cinoptions=(0,u0,+0,l1,g0

" Key Mappings
let mapleader = ","

" Clear search highlighting
nnoremap <silent> <leader>/ :nohlsearch<CR>

" Fast write and quit
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>x :wq<CR>

" Buffer navigation
nnoremap <leader>n :bnext<CR>
nnoremap <leader>p :bprevious<CR>

" Vertical and horizontal splits
nnoremap <leader>v :vsplit<CR>
nnoremap <leader>h :split<CR>

" File Type Detection
filetype on
filetype plugin on
filetype indent on

" C/C++ specific settings
autocmd FileType c,cpp setlocal commentstring=//%s
autocmd FileType c,cpp setlocal equalprg=clang-format
autocmd FileType c,cpp set include=^\\s*#\\s*include
