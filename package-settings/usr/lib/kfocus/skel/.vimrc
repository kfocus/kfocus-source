" ====[ KFocus Default VIM Configuration ~/.vimrc ]===================
" Assembled by Michael Mikowski <mmikowski@kfocus.org>
"   and Damian Conway, with settings provided in the example vimrc
"   provided by Bram Moolenaar <bram@vim.org>.

" To try with neovim, copy to or symlink per the 'Where should I put
"   my config (vimrc)?' section in the neovim FAQ at
"   https://github.com/neovim/neovim/wiki/FAQ

" The matchit plugin makes the % command work better, but it is not backwards
" compatible. The ! means the package won't be loaded right away but when
" plugins are loaded during initialization.
if has('syntax') && has('eval')
  packadd! matchit
endif

" ====[ Git Configs ]=================================================
" Keep All HEAD content in merge
map ;g1 :%s?^<<<\+ HEAD\s*\n\(\_.\{-}\)\n===\+\n\(\_.\{-}\)>>>\+.*$?\1?gc<CR>
" Discard All HEAD content in merge
map ;g2 :%s?^<<<\+ HEAD\s*\n\(\_.\{-}\)\n===\+\n\(\_.\{-}\)>>>\+.*$?\2?gc<CR>

" ====[ Backup and undo ]=============================================
" See https://stackoverflow.com/questions/743150
set undofile
set undolevels=1000         " How many undos
set undoreload=10000        " number of lines to save for undo

set backup                  " keep a backup file (restore to previous version)
if has('persistent_undo')
  set undofile                      " keep an undo file (undo changes after closing)
endif
set swapfile                        " enable swaps
set undodir=$HOME/.vim/tmp/undo     " undo files
set backupdir=$HOME/.vim/tmp/backup " backups
set directory=$HOME/.vim/tmp/swap   " swap files

" Make those folders automatically if they don't already exist.
if !isdirectory(expand(&undodir))
    call mkdir(expand(&undodir), "p")
endif
if !isdirectory(expand(&backupdir))
    call mkdir(expand(&backupdir), "p")
endif
if !isdirectory(expand(&directory))
    call mkdir(expand(&directory), "p")
endif

" ====[ Files and buffers ]============================================
autocmd BufWrite * :set ff=unix "Autoconvert to unix line endings
filetype plugin on  "Identify syntax
set autoread        "Reload buffer when external change detected
set autowrite       "Save buffer when changing files
" Reduce IO latency by using SSD
"   See http://unix.stackexchange.com/questions/37076
set dir=/tmp
set fileformats=unix,mac,dos
set noautoread
set viminfo=h,'50,<10000,s1000,/1000,:100 " What to save in .viminfo

" ====[ Colors and highlights ]========================================
" colorscheme elflord
hi LineNr ctermfg=white ctermbg=gray
highlight CursorColumn term=bold ctermfg=black ctermbg=green
map <silent> ;c :set cursorcolumn!<CR>
set background=dark "When guessing, guess bg is dark (vs light)
set number
set modeline

" Only set termcolors for certain terminals. This leaves
" Virtual Terminals to use available colors
if $COLORTERM == 'truecolor' || $TERM == 'xterm-256color'
  set termguicolors
endif

" ====[ Indentation ]==================================================
set autoindent      "Retain indentation on next line
set mouse=c         "Fix neovim behavior
set smartindent     "Turn on autoindenting of blocks
set textwidth=78    "Wrap at column 78
set nojoinspaces    "Single-space after periods during wrap
" See https://groups.google.com/forum/#!topic/comp.editors/HEx4QcEwV5U
" set wrapmargin=78

" Indent/outdent current block
map %% $>i
map $$ $<i

" Disable magic outdenting of comments
inoremap # X<C-H>#

" Make BS/DEL work as expected
vmap <BS> x

" Fold (see /usr/share/vim/vim73/syntax/javascript.vim
let javaScript_fold=0
set foldlevel=99

" ====[ Tab formating ]================================================
set expandtab       "Convert all tabs that are typed to spaces
set shiftround      "Indent/outdent to nearest tabstop
set shiftwidth=2    "Indent/outdent by two columns
set tabstop=2       "Indentation levels every two columns

" Convert between spaces and tabs
map <silent> TS :set   expandtab<CR>:%retab!<CR>
map <silent> TT :set noexpandtab<CR>:%retab!<CR>

" ====[ Visual modes ]================================================
" Visual Block mode is far more common that Visual mode...
nnoremap v <C-V>
nnoremap <C-V> v

set virtualedit=block "Square up visual selections

" =====[ Toggle syntax highlighting ]==================================
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

" =====[ Add or subtract comments ]===============================
function! ToggleComment ()
  let currline = getline(".")
  if currline =~ '^#'
    s/^#//
  elseif currline =~ '\S'
    s/^/#/
  endif
endfunction
map <silent> # :call ToggleComment()<CR>j0

" =====[ Keyboard shortcuts ]======================================
" Keycodes and maps timeout in 3/10 sec...
set timeout timeoutlen=300 ttimeoutlen=300

" H Switch off highlighting till next search
" map H :nohlsearch<CR>

" e Edit a file
map e :n

" ;k Remove trailing space
map ;k :%s?\s\+$??<CR>

" ;n Highlight or replace non-ascii characters
map ;n /[^\x00-\x7F]<CR>
map ;nn :%s?[^\x00-\x7F]? ?gc<CR>

" ;l Remove double spaces after punctuation marks
map ;l :%s?\([\.!?]\) \s\+?\1 ?gc<CR>

" ;v Paste from clipboard fast
map ;v :set paste<CR>:r !xsel --clipboard --output<CR>:set nopaste<CR>

" C-J format JSON blob and tighten up leading and single-line entries
map <C-J> :set paste<CR>1Givar j = GA; console.log(JSON.stringify(j,null,2));1G^vG:!node<CR> :%s?^\(\s*{\)\s*\n\s*?\1 ?g<CR>:%s?^\(\s*{[^,}]*\)\n\s*}?\1 }?g<CR>
" C-K blobify JSON
map <C-K> :set paste<CR>1Givar j = GA; console.log(JSON.stringify(j));1G^vG:!node<CR>

";y Toggle syntax highlighting
nmap <silent> ;y : call ToggleSyntax() <CR>

" ;f ;ff Turn numbers on and off
nmap <silent> ;f  :set nonu <CR>
nmap <silent> ;ff :set nu   <CR>

" =====[ Visual selections keyboard shortcuts ]====================
" ;p Format CSS into PowerCSS rule map
vmap ;p :s?^\s*\([^ ]\+\)\(\s*\):\s*\([^;]\+\);?    _\1_\2: '_\3_',?g<CR>

" ;q Format selection for JS string, ;h undoes
vmap <silent> ;q :s?^\(\s*\)\(.*\)\s*$?      + \1'\2'?<CR>
vmap <silent> ;h :s?^\(\s*\)+\(\s*\)'\([^']\+\)',*\s*$?\1\2\3?g<CR>

" ;r Round all numbers on a line to n places (see SVG)
vmap <silent> ;r :s?\d\+\.\d\+?\=printf('%.0f',str2float(submatch(0)))?gc<CR>
vmap <silent> ;rr :s?\d\+\.\d\d\+?\=printf('%.1f',str2float(submatch(0)))?gc<CR>
vmap <silent> ;rrr :s?\d\+\.\d\d\d\+?\=printf('%.2f',str2float(submatch(0)))?gc<CR>

" ;t Trim trailing zeros
vmap <silent> ;t :s?\(\d\+\)\.0\+\([^0-9]\)?\1\2?gc<CR>

" ;w Visual apply optimal text wrap
vmap ;w gq

" ====[ Miscellaneous ]================================================
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

" Turn off stupid-huge html indents
" per https://vi.stackexchange.com/questions/10128
au FileType html setlocal indentexpr=''

" Execute from selected lines
" See https://stackoverflow.com/questions/14385998
nnoremap <F2> :exe getline(".")<CR>
vnoremap <F2> :<C-w>exe join(getline("'<","'>"),'<Bar>')<CR>

" See https://superuser.com/questions/271471
" Change camelCase to snake_case
vnoremap ,u :s/\<\@!\([A-Z]\)/\_\l\1/g<CR>gul
" Change snake_case to camelCase
vnoremap ,c :s/_\([a-z]\)/\u\1/g<CR>gUl

" =====[ Smarter searching ]===========================================
set hlsearch                        "Highlight all search matches
set ignorecase                      "Ignore case in all searches...
set incsearch                       "Lookahead as search pattern specified
set smartcase                       " ...unless uppercase letters used

" =====[ Dictionary setup (use Ctrl-x Ctrl-k to complete words) ] =====
" =====[ Thesaurus setup (use Ctrl-x Ctrl-t to show alternates) ] =====
set dictionary+=/etc/dictionaries-common/words
set thesaurus+=/usr/local/share/thesaurus/mthesaur.txt

" =====[ Markdown Enhancements for Embedded Code Syntax ] ==============
" https://vimtricks.com/p/highlight-syntax-inside-markdown/
" See :r !ls /usr/share/vim/vim82/syntax/
"
let g:markdown_fenced_languages = ['bash','css','erb=eruby','javascript','js=javascript','json','html','node=javascript','perl','php=perl','python','ruby','sass','xml','vim']

" ====[ Use this to size comment lines ]===============================
" =====================================================================
" ====[ END ]==========================================================
