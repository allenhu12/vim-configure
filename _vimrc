""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let $MYVIMRC='~/.vim/_vimrc'
set nocompatible
set fileencodings=utf-8,gb2312,gbk,gb18030  
set termencoding=utf-8  
set encoding=utf-8 
syntax on
set diffexpr=MyDiff()
function MyDiff()
  let opt = '-a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  let eq = ''
  if $VIMRUNTIME =~ ' '
    if &sh =~ '\<cmd'
      let cmd = '""' . $VIMRUNTIME . '\diff"'
      let eq = '"'
    else
      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
    endif
  else
    let cmd = $VIMRUNTIME . '\diff'
  endif
  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
endfunction

"customized
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""



"""""""""""""""""""""""""""""""""""""""""""""""help"""""""""""""""""""""""""""""""""""""""""""""""""""
" vundle {
"set rtp+=~/.vim/bundle/vundle/
" Èç¹ûÔÚwindowsÏÂÊ¹ÓÃµÄ»°£¬ÉèÖÃÎª 
" set rtp+=$HOME/.vim/bundle/vundle/
"call vundle#rc()
" }
"
" let Vundle manage Vundle
" required! 
"Bundle 'gmarik/vundle'
 
" My Bundles here:
"
" original repos on github
" githubÉÏµÄÓÃ»§Ğ´µÄ²å¼ş£¬Ê¹ÓÃÕâÖÖÓÃ»§Ãû+repoÃû³ÆµÄ·½Ê½
" Bundle 'tpope/vim-fugitive'
" Bundle 'Lokaltog/vim-easymotion'
" Bundle 'rstacruz/sparkup', {'rtp': 'vim/'}
" Bundle 'tpope/vim-rails.git'
" vim-scripts repos
" vimscriptsµÄrepoÊ¹ÓÃÏÂÃæµÄ¸ñÊ½£¬Ö±½ÓÊÇ²å¼şÃû³Æ
"Bundle 'taglist.vim'
"Bundle 'SuperTab'
"Bundle 'vimwiki'
"Bundle 'winmanager'
"Bundle 'bufexplorer.zip'
"Bundle 'The-NERD-tree'
"Bundle 'matrix.vim--Yang'
"Bundle 'FencView.vim'
"Bundle 'Conque-Shell'
"Bundle 'Vimpress'
"Bundle 'Markdown'
"Bundle 'LaTeX-Suite-aka-Vim-LaTeX'
"Bundle 'c.vim'
"Bundle 'snipMate'
 
" non github reposo
" ·ÇgithubµÄ²å¼ş£¬¿ÉÒÔÖ±½ÓÊ¹ÓÃÆägitµØÖ·
" Bundle 'git://git.wincent.com/command-t.git'
" ...
 
"
" Brief help
" :BundleList          - list configured bundles
" :BundleInstall(!)    - install(update) bundles
" :BundleSearch(!) foo - search(or refresh cache first) for foo
" :BundleClean(!)      - confirm(or auto-approve) removal of unused bundles
" vundleÖ÷Òª¾ÍÊÇÉÏÃæÕâ¸öËÄ¸öÃüÁî£¬ÀıÈçBundleInstallÊÇÈ«²¿ÖØĞÂ°²×°£¬BundleInstall!ÔòÊÇ¸üĞÂ
" Ò»°ã°²×°²å¼şµÄÁ÷³ÌÎª£¬ÏÈBundleSearchÒ»¸ö²å¼ş£¬È»ºóÔÚÁĞ±íÖĞÑ¡ÖĞ£¬°´i°²×°
" °²×°ÍêÖ®ºó£¬ÔÚvimrcÖĞ£¬Ìí¼ÓBundle 'XXX'£¬Ê¹µÃbundleÄÜ¹»¼ÓÔØ£¬Õâ¸ö²å¼ş£¬Í¬Ê±Èç¹û
" ĞèÒªÅäÖÃÕâ¸ö²å¼ş£¬Ò²ÊÇÔÚvimrcÖĞÉèÖÃ¼´¿É
" see :h vundle for more details or wiki for FAQ
"" NOTE: comments after Bundle command are not allowed..

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


"""""""""""""""""""""""""""""""""""""""""""""""vundle"""""""""""""""""""""""""""""""""""""""""""""""""
filetype off        " required!
set rtp+=~/.vim/bundle/vundle/
"set rtp+=$HOME/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
Bundle 'gmarik/vundle'

" githubÉÏµÄÓÃ»§Ğ´µÄ²å¼ş£¬Ê¹ÓÃÕâÖÖÓÃ»§Ãû+repoÃû³ÆµÄ·½Ê½
Bundle 'Lokaltog/vim-easymotion'
Bundle  'scrooloose/nerdcommenter'
Bundle 'nelson/cscope_maps'

"¸ñÊ½2£ºvim-scriptsÀïÃæµÄ²Ö¿â£¬Ö±½Ó´ò²Ö¿âÃû¼´¿É¡£
Bundle 'L9'
Bundle 'FuzzyFinder'
Bundle 'The-NERD-tree'
"the buf_it.vim under e:/program files/vim/plugin is used, it is specially customized, we igore the git buf_it here
"Bundle 'buf_it'
Bundle 'taglist.vim'
Bundle 'SuperTab'
Bundle 'EasyGrep'
Bundle 'matchit.zip'
Bundle 'YankRing.vim'
Bundle 'Mark'
Bundle 'Conque-Shell'
Bundle 'FencView.vim'
Bundle 'Gundo'
filetype plugin indent on
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""miscellaneous"""""""""""""""""""""""""""""""""""""""""""
set guitablabel=%N\ %f
"set encoding=utf-8
" for windows vim {
"set guifont=Microsoft_YaHei_Mono:h11:cGB2312
"source $VIMRUNTIME/vimrc_example.vim
"source $VIMRUNTIME/mswin.vim
"behave mswin
"}

color solarized
"color molokai
"set bg=light
set bg=dark
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set scrolloff=3
set autoindent
set showmode
set showcmd
set hidden
set wildmenu
set wildmode=list:longest
"set visualbell
"set cursorline
set ttyfast
"set ruler
set noruler
set backspace=indent,eol,start
set relativenumber
set undofile

let mapleader = ","
"nnoremap / /\v
"vnoremap / /\v
set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
set statusline =%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
set laststatus=2
"Set to auto read when a file is changed from the outside
set autoread

nnoremap <leader><space> :noh<cr>
nnoremap <tab> %
vnoremap <tab> %

set wrap
set textwidth=79
set formatoptions=qrn1
set colorcolumn=138

nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
"inoremap <up> <nop>
"inoremap <down> <nop>
"inoremap <left> <nop>
"inoremap <right> <nop>
nnoremap j gj
nnoremap k gk
",re manually refresh the buffer
nnoremap <leader>re :bufdo e<CR>
nnoremap ; :

"ÉèÖÃ¿ì½İ¼ü½«Ñ¡ÖĞÎÄ±¾¿é¸´ÖÆÖÁÏµÍ³¼ôÌù°å
vnoremap<Leader>y "+y

"ÉèÖÃ¿ì½İ¼ü½«ÏµÍ³¼ôÌù°åÄÚÈİÕ³ÌùÖÁvim
nmap<Leader>p "+p

"Y copy one line triming the spaces begin and end, you can use :di to see the
"register contents and Ctrl+r+<num> to copy the according register in insert mode
"note: ctrl+r+' " ' would insert the lastest register, 
"note: ctrl+r+' * ' would insert the clipboard
nmap Y ^y$

"D means delete forever(note, use the visual mode to select the texts you want
"to delete firstly, that is why vnoremap is used), not found in the lastest register, use c for cut
vnoremap D "_d
",cd change to current open files directory
"" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>
"nnoremap <Leader>cd :lcd %:p:h<CR> 


" Move a line of text using ALT+[jk] or Comamnd+[jk] on mac
" to map ALT-j, you have to use set <m-j> =ctrl-v + alt-j
set <m-j> =j
nmap <m-j> mz:m+<cr>`z
set <m-k> =k
nmap <m-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z
" ALT-a means select all
set <m-a> =a 
map <m-a> ggVG

""""""""""""""""""""""""""""""
" => Visual mode related
""""""""""""""""""""""""""""""
" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>
au FocusLost * :wa

"F2 to toggle the paste mode
set pastetoggle=<F2>
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""plugin customized"""""""""""""""""""""""""""""""""""""
"buf_it settings = {

"ctrl+h ctrl+l
nmap  <C-h>      :call BufPrevPart()<cr>
nmap  <C-l>      :call BufNextPart()<cr>
"close the current buf
nnoremap <Leader>q  :call BufClose()<CR> 
"save and close the current buf
nnoremap <Leader>wq :w<CR><Esc>:call BufClose()<CR> 
"save the current buf
nnoremap <Leader>w  :w<CR> 
"}


"The NERD-Tree settings = {
nnoremap <leader>n   :NERDTree<cr>
nnoremap <leader>nb  :Bookmark 
nnoremap <leader>nob :OpenBookmark 
nnoremap <leader>N   :NERDTreeClose<cr>         
let NERDTreeWinPos ="left"                      "½«NERDTreeµÄ´°¿ÚÉèÖÃÔÚgvim´°¿ÚµÄ×ó±ß
let NERDTreeShowBookmarks=1                     "µ±´ò¿ªNERDTree´°¿ÚÊ±£¬×Ô¶¯ÏÔÊ¾Bookmarks
let NERDTreeChDirMode=2                         "´ò¿ªÊéÇ©Ê±£¬×Ô¶¯½«VimµÄpwdÉèÎª´ò¿ªµÄÄ¿Â¼£¬Èç¹ûÄãµÄÏîÄ¿ÓĞtagsÎÄ¼ş£¬Äã»á·¢ÏÖÕâ¸öÃüÁîºÜÓĞ°ïÖú
"}
"The taglist settings = {
let Tlist_Use_Right_Window=1
nmap<Leader>t :TlistToggle<cr>
"}

"The supertab settings = {
filetype plugin indent on
set completeopt=longest,menu
"supertab
let g:SuperTabRetainCompletionType=2
let g:SuperTabDefaultCompletionType="<C-X><C-O>"
"easy motion
"let g:EasyMotion_leader_key = '<,>'
"}


"The FuzzyFinder settings = {
nnoremap <Leader>ff  :FufFile<cr>
nnoremap <Leader>fd  :FufDir<cr>
nnoremap <Leader>fb  :FufBuffer<cr>
" ctrl+shift+F would open the all files under the current dir to search
map <C-S-F> :FufFileRecursive<CR>
"};
"
"The quickfix settings = {
function! GetBufferList()
  redir =>buflist
  silent! ls
  redir END
  return buflist
endfunction

function! ToggleList(bufname, pfx)
  let buflist = GetBufferList()
  for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ "'.a:bufname.'"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if bufwinnr(bufnum) != -1
      exec(a:pfx.'close')
      return
    endif
  endfor
  if a:pfx == 'l' && len(getloclist(0)) == 0
      echohl ErrorMsg
      echo "Location List is Empty."
      return
  endif
  let winnr = winnr()
  exec(a:pfx.'open')
  if winnr() != winnr
    wincmd p
  endif
endfunction

"nmap <silent> <leader>l :call ToggleList("Location List", 'l')<CR>
"nmap <silent> <leader>e :call ToggleList("Quickfix List", 'c')<CR>
command -bang -nargs=? QFix call QFixToggle(<bang>0)
function! QFixToggle(forced)
  if exists("g:qfix_win") && a:forced == 0
    cclose
    unlet g:qfix_win
  else
    copen 10
    let g:qfix_win = bufnr("$")
  endif
endfunction
" ,f toggle the quickfix window
nmap <silent> <Leader>f :QFix<CR>
"}


"The Mark settings = {
nmap <silent> ,hl <Plug>MarkSet
vmap <silent> ,hl <Plug>MarkSet
nmap <silent> ,hh <Plug>MarkClear
vmap <silent> ,hh <Plug>MarkClear
nmap <silent> ,hr <Plug>MarkRegex
vmap <silent> ,hr <Plug>MarkRegex
"}

"The EasyGrep settings = {
"<leader>vv- Grep for the word under the cursor
"<leader>va - Like vv, but add to existing list
"<leader>vo - Select the files to search in and set grep options
":Grep SearchString
map f/ <esc>:Grep
"}


"The gundo settings = {
nnoremap <F11> :GundoToggle<CR>
nnoremap <F12> :earlier 100000<CR>

"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! VisualSelection(direction) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", '\\/.*$^~[]')
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'b'
        execute "normal ?" . l:pattern . "^M"
    elseif a:direction == 'gv'
        call CmdLine("vimgrep " . '/'. l:pattern . '/' . ' **/*.')
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    elseif a:direction == 'f'
        execute "normal /" . l:pattern . "^M"
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction

