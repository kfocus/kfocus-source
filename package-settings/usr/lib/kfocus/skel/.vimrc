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

" A vim native way to match tags:
" https://stackoverflow.com/questions/6270396
" Use :help v_it OR :help visual-operators
" 1. Place cursor on Tag
" 2. Type `vat` for outer tag block, `vit` for inner tag
" 3. Type `o` or `O` to jump to opening or closing tag
" Optional: Type `it` or `at` to expand or shrink selection
" Optional: Type `esc` to exit, `c` to change, `y` to cop

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
" See https://unix.stackexchange.com/questions/75430
" Use of 'e' at the end of regex to suppresses error if no trailing space
autocmd BufWritePre * :call TrimTrailingWhiteSpace() "Autoremove all trailing space
autocmd BufWrite    * :set ff=unix                   "Autoconvert to unix line endings
filetype plugin on  "Identify syntax
set autoread        "Reload buffer when external change detected
set autowrite       "Save buffer when changing files

set fileformats=unix,mac,dos
set noautoread
set viminfo=h,'50,<10000,s1000,/1000,:100 "Set values to save to .viminfo

" ====[ Colors and highlights ]========================================
" colorscheme elflord
hi LineNr ctermfg=white ctermbg=gray
highlight CursorColumn term=bold ctermfg=black ctermbg=green
" show cursor row and column
map <silent> ;c :set cursorcolumn!<CR>:set cursorline!<CR>
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
set virtualedit=block "Square up visual selections

" =====[ Toggle syntax highlighting ]==================================
function! ToggleSyntax ()
  " We expect an IDE to provide its own highlighting
  if !has('ide')
    if g:f_syntax == 1
      syntax off
      let g:f_syntax = 0
    else
      syntax on
      let g:f_syntax = 1
    endif
  endif
endfunction

if exists("syntax_on")
   let g:f_syntax = 1
else
   let g:f_syntax = 0
   call ToggleSyntax()
endif

" =====[ Add or subtract comments ]================================
function! ToggleComment ()
  let currline = getline(".")
  if currline =~ '^#'
    s/^#//
  elseif currline =~ '\S'
    s/^/#/
  endif
endfunction
map <silent> # :call ToggleComment()<CR>j0

" =====[ Trim trailing whitespace ]================================
" This is used in ;k shortcut and on file save
function! TrimTrailingWhiteSpace ()
  " We expect an IDE to provide its own trimming
  if !has('ide')
    let wv = winsaveview()
    %s/\s\+$//ge
    call winrestview(wv)
  endif
endfunction

" =====[ Keyboard shortcuts ]======================================
" Keycodes and maps timeout in 3/10 sec...
set timeout timeoutlen=300 ttimeoutlen=300

" Clear search highlights by pressing Ctrl + L
nnoremap <C-l> :nohlsearch<CR><C-l>

" e Edit the next file
" Conflicts with normal use of e to move forward to a word, disabled by
" default.
"
" map e :n

" ;k Trim trailing space, ;kk clears checkboxes
map <silent> ;k  :call TrimTrailingWhiteSpace()<CR>
map <silent> ;kk :%s?\(\W\)\[.\] ?\1[ ] ?<CR>

" ;n Highlight or replace non-ascii characters
map ;n /[^\x00-\x7F]<CR>
map ;nn :%s?[^\x00-\x7F]? ?gc<CR>

" ;l Remove double spaces after punctuation marks
map ;l :%s?\([\.!?]\) \s\+?\1 ?gc<CR>

" ;v Paste from clipboard fast
"   You may need to use this for X11 sessions with xsel:
"   map ;v :set paste<CR>:r !xsel --clipboard --output<CR>:set nopaste<CR>
" The following works with Wayland and XWayland apps
map ;v :set paste<CR>:-1r !wl-paste<CR>:set nopaste<CR>

" C-J format JSON blob and tighten up leading and single-line entries
map <C-J> :set paste<CR>1Givar j = GA; console.log(JSON.stringify(j,null,2));1G^vG:!node<CR> :%s?^\(\s*{\)\s*\n\s*?\1 ?g<CR>:%s?^\(\s*{[^,}]*\)\n\s*}?\1 }?g<CR>
" C-K blobify JSON
map <C-K> :set paste<CR>1Givar j = GA; console.log(JSON.stringify(j));1G^vG:!node<CR>

";y Toggle syntax highlighting
nmap <silent> ;y : call ToggleSyntax() <CR>

" ;f toggle line numbers
nmap <silent> ;f  :set invnumber <CR>

" =====[ Visual selections keyboard shortcuts ]====================
" ;p Format CSS into PowerCSS rule map
vmap ;p :s?^\s*\([^ ]\+\)\(\s*\):\s*\([^;]\+\);?    _\1_\2: '_\3_',?g<CR>

" ;q Format selection for JS string, ;h undoes
vmap <silent> ;q :s?^\(\s*\)\(.*\)\s*$?      + \1'\2'?<CR>
vmap <silent> ;h :s?^\(\s*\)+\(\s*\)'\([^']\+\)',*\s*$?\1\2\3?g<CR>

" ;r Round all numbers on a line to n places (see SVG)
" https://stackoverflow.com/questions/41330466
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
au FileType html setlocal shiftwidth=2 tabstop=2 indentexpr=''
au FileType md   setlocal shiftwidth=2 tabstop=2 indentexpr=''

" Execute from selected lines
" See https://stackoverflow.com/questions/14385998
nnoremap <F2> :exe getline(".")<CR>
vnoremap <F2> :<C-w>exe join(getline("'<","'>"),'<Bar>')<CR>

" See https://superuser.com/questions/271471
" Convert selected lines camelCase to snake_case
vnoremap ,u :s/\<\@!\([A-Z]\)/\_\l\1/g<CR>
" Convert selected lines snake_case to camelCase
vnoremap ,c :s/_\([a-z]\)/\u\1/g<CR>
" Convert selected lines to Pascal Case
vnoremap ,p :s/\<\w/\u&/g<CR>:nohlsearch<CR>

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
let g:markdown_fenced_languages = ['bash','changelog','css','erb=eruby','javascript','js=javascript','json','html','log=messages','messages','node=javascript','perl','php=perl','python','ruby','sass','sql','xml','vim','yaml']

" Support fenced syntax highlighing for longer files (10k lines).
" Reduce to minlines value or disable if editing is slow.
" See https://github.com/vim/vim/issues/2790
syntax sync minlines=10000

" Run only for markdown files; highlight backtick and bold text by color
autocmd FileType markdown call s:MarkdownCustomHighlights()

function! s:MarkdownCustomHighlights()
  " Color for inline code ticks (e.g., `code`)
  highlight markdownCode ctermfg=Cyan guifg=Cyan

  " Color for bold text (e.g., **bold**)
  highlight markdownCode ctermfg=Cyan guifg=Cyan
  highlight htmlBold ctermfg=Red guifg=Red cterm=bold gui=bold
endfunction

" =====[ Wrap for vimdiff, both panes ] ===============================
function! VimdiffWrap ()
  windo setlocal wrap      " Enable line wraps in local buffers
  windo setlocal linebreak " Break lines at words
  windo setlocal nolist    " Do not show special chars
endfunction
au VimEnter * if &diff | call VimdiffWrap() | endif

" =====[ Fix for pattern uses more memory than 'maxmempattern' ] ======
" See https://github.com/vim/vim/issues/2049
" MAY be resolved in vim 9.0. Tends to happen in Markdown syntax
set mmp=20000 " was set mmp=5000

" =====[ From defaults.vim: Remember cursor position ]=================
if 1
  " Put these in an autocmd group, so that you can revert them with:
  " :augroup vimStartup | au! | augroup END
  augroup vimStartup
    au!
    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid, when inside an event handler
    " (happens when dropping a file on gvim) and for a commit message (it's
    " likely a different one than last time).
    autocmd BufReadPost *
      \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
      \ |   exe "normal! g`\""
      \ | endif
  augroup END
endif

" ====[ Use this to size comment lines ]===============================
" =====================================================================
" ====[ END ]==========================================================

