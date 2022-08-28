autocmd BufWrite * :set ff=unix 
filetype plugin on
set autoread        
set autowrite       
set dir=/tmp
set fileformats=unix,mac,dos
set noautoread
set viminfo=h,'50,<10000,s1000,/1000,:100 
set number
set relativenumber
set modeline
set nowrap
set autoindent     
set mouse=c 
set smartindent 
set textwidth=78 
set wrapmargin=78
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
set matchpairs+=<:>
set nomore
set noshowmode                
set ruler
set scrolloff=2
set title
set titleold=
set updatecount=10
set wildmode=list:longest,full
set backspace=indent,eol,start
set hlsearch 
set ignorecase
set incsearch
set smartcase
set dictionary+=/etc/dictionaries-common/words
set thesaurus+=/usr/local/share/thesaurus/mthesaur.txt
set virtualedit=block 

if exists ('termguicolors')
  let &t_8f =  "\<Esc>[38:2:%lu:%lu:%lum"
  let &t_8b =  "\<Esc>[48:2:%lu:%lu:%lum"
  set t_Co=256
  set termguicolors
endif

colorscheme industry