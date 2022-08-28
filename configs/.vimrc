autocmd BufWrite * :set ff=unix 
filetype plugin on
set autoread        
set autowrite       
set dir=/tmp
set fileformats=unix,mac,dos
set noautoread
set viminfo=h,'50,<10000,s1000,/1000,:100 

hi LineNr ctermfg=white ctermbg=gray
highlight CursorColumn term=bold ctermfg=black ctermbg=green
map <silent> ;c :set cursorcolumn!<CR>
set number
set relativenumber
set modeline
set nowrap

if exists ('termguicolors')
  let &t_8f =  "\<Esc>[38:2:%lu:%lu:%lum"
  let &t_8b =  "\<Esc>[48:2:%lu:%lu:%lum"
  set t_Co=256
  set termguicolors
endif

set autoindent     
set mouse=c 
set smartindent 
set textwidth=78 
set wrapmargin=78

map %% $>i
map $$ $<i

inoremap # X<C-H>#

vmap <BS> x

let javaScript_fold=0
set foldlevel=99

set shiftround      
set shiftwidth=4   
set tabstop=4      
set ruler
set smarttab
set smartindent
set icon
set hidden
set ttyfast
hi StatusLineNC term=bold cterm=bold gui=bold
hi StatusLine term=bold cterm=bold gui=bold
map <silent> TS :set   expandtab<CR>:%retab!<CR>
map <silent> TT :set noexpandtab<CR>:%retab!<CR>

nnoremap v <C-V>
nnoremap <C-V> v

set virtualedit=block 

function! ToggleSyntax()
  if g:f_syntax == 1
    syntax off
    let g:f_syntax = 0
  else
    syntax on
    let g:f_syntax = 1
  endif
endfunction

if exists("syntax_on")
   let g:f_syntax = 1
else
   let g:f_syntax = 0
   call ToggleSyntax()
endif

function! ToggleComment ()
  let currline = getline(".")
  if currline =~ '^#'
    s/^#//
  elseif currline =~ '\S'
    s/^/#/
  endif
endfunction
map <silent> # :call ToggleComment()<CR>j0

set timeout timeoutlen=300 ttimeoutlen=300
map e :n
map ;k :%s?\s\+$??<CR>
map ;l :%s?\([\.!?]\) \s\+?\1 ?gc<CR>
map ;v :set paste<CR>:r !xsel --clipboard --output<CR>:set nopaste<CR>
map <C-J> :set paste<CR>1Givar j = GA; console.log(JSON.stringify(j,null,2));1G^vG:!node<CR>
map <C-K> :set paste<CR>1Givar j = GA; console.log(JSON.stringify(j));1G^vG:!node<CR>
nmap <silent> ;y : call ToggleSyntax() <CR>
nmap <silent> ;f  :set nonu <CR>
nmap <silent> ;ff :set nu   <CR>
vmap ;p :s?^\s*\([^ ]\+\)\(\s*\):\s*\([^;]\+\);?    _\1_\2: '_\3_',?g<CR>
vmap <silent> ;q :s?^\(\s*\)\(.*\)\s*$?      + \1'\2'?<CR>
vmap <silent> ;h :s?^\(\s*\)+\(\s*\)'\([^']\+\)',*\s*$?\1\2\3?g<CR>
vmap <silent> ;r :s?\d\+\.\d\+?\=printf('%.0f',str2float(submatch(0)))?gc<CR>
vmap <silent> ;rr :s?\d\+\.\d\d\+?\=printf('%.1f',str2float(submatch(0)))?gc<CR>
vmap <silent> ;rrr :s?\d\+\.\d\d\d\+?\=printf('%.2f',str2float(submatch(0)))?gc<CR>
vmap <silent> ;t :s?\(\d\+\)\.0\+\([^0-9]\)?\1\2?gc<CR>
vmap ;w gq

set matchpairs+=<:>                 "Match angle brackets too
set nomore                          "Don't page long listings
set noshowmode                      "Suppress mode change messages
set ruler                           "Show cursor location info on status line
set scrolloff=2                     "Scroll when 2 lines from top/bottom
set title                           "Show filename in titlebar of window
set titleold=
set updatecount=10                  "Save buffer every 10 chars typed
set wildmode=list:longest,full      "Show list of completions
set backspace=indent,eol,start      "BS past autoindents, boundaries, insertion
nnoremap <F2> :exe getline(".")<CR>
vnoremap <F2> :<C-w>exe join(getline("'<","'>"),'<Bar>')<CR>
noremap <up> :echoerr "Use K instead" <CR>
noremap <down> :echoerr "Use J instead" <CR>
noremap <left> :echoerr "Use H instead" <CR>
noremap <right> :echoerr "Use L instead" <CR>
inoremap <up> <NOP>
inoremap <down> <NOP>
inoremap <left> <NOP>
inoremap <right> <NOP>
noremap <silent> <C-Left> :vertical resize +3<CR>
noremap <silent> <C-Right> :vertical resize -3<CR>
noremap <silent> <C-Up> :resize +3<CR>
noremap <silent> <C-Down> :resize -3<CR>
vnoremap ,u :s/\<\@!\([A-Z]\)/\_\l\1/g<CR>gul
vnoremap ,c :s/_\([a-z]\)/\u\1/g<CR>gUl

set hlsearch                    "Highlight all search matches
set ignorecase                  "Ignore case in all searches...
set incsearch                   "Lookahead as search pattern specified
set smartcase                   "...unless uppercase letters used
set dictionary+=/etc/dictionaries-common/words
set thesaurus+=/usr/local/share/thesaurus/mthesaur.txt

filetype plugin indent on
inoremap " ""<left>
inoremap ' ''<left>
inoremap ( ()<left>
inoremap [ []<left>
inoremap { {}<left>
inoremap {<CR> {<CR>}<ESC>O
inoremap {;<CR> {<CR>};<ESC>

