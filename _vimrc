
"===================================================================="
"====><<Windows or Linux, terminal or gvim>>
"===================================================================="
let g:iswindows = 0
let g:ismac = 0
let g:islinux = 0
let g:isGUI = 0

if has("unix")
    let s:uname = system("uname -s")
    if s:uname == "Darwin\n"
        let g:ismac = 1
    else
        let g:islinux = 1
    endif
elseif (has("win32") || has("win64") || has("win95") || has("win16"))
    let g:iswindows = 1
endif

if has("gui_running")
    let g:isGUI = 1
else
    let g:isGUI = 0
endif
"===================================================================="
"===================================================================="



"===================================================================="
"====> Windows platform>{
"===================================================================="
if(g:iswindows && g:isGUI)

endif
"}
"===================================================================="
"===================================================================="



"===================================================================="
"====><Linux platform> {
"===================================================================="
if !g:iswindows
	if g:isGUI
	"Source a global configuration file if available
        if filereadable("/etc/vim/gvimrc.local")
            source /etc/vim/gvimrc.local
        endif
        set nowrap

	else
		set mouse=a				"enable mouse
		set t_Co=256     		"enable 256 colors in terminal
		set backspace=2			"enable backspace
        set wrap                "enable it under non-gui
		if filereadable("/etc/vim/vimrc.local")
			source /etc/vim/vimrc.local
		endif
	endif
endif
"}
"===================================================================="
"===================================================================="





syntax on                   "coloful vim
set nocompatible
set fileencodings=utf-8,gb2312,gbk,gb18030  
set termencoding=utf-8  
set encoding=utf-8 
"filetype off				"disable filetype detection





"===================================================================="
"====>Vundle configuration{
"===================================================================="
if !g:iswindows
	set rtp+=~/.vim/bundle/vundle/
	call vundle#rc()
else
	set rtp+=$VIM/vimfiles/bundle/vundle/
	call vundle#rc('$VIM/vimfiles/bundle/')
endif

Bundle 'gmarik/vundle'

" My Bundles here:
"Bundle 'Lokaltog/vim-easymotion'
"Bundle 'scrooloose/nerdcommenter'
"Bundle 'nelson/cscope_maps'
"Bundle 'kien/ctrlp.vim'
"Bundle 'tpope/vim-repeat'
""¸ñÊ½2£ºvim-scriptsÀïÃæµÄ²Ö¿â£¬Ö±½Ó´ò²Ö¿âÃû¼´¿É¡£
"Bundle 'L9'
"Bundle 'FuzzyFinder'
"Bundle 'The-NERD-tree'
""the buf_it.vim under e:/program files/vim/plugin is used, it is specially customized, we igore the git buf_it here
""Bundle 'buf_it'
"Bundle 'taglist.vim'
"Bundle 'SuperTab'
"Bundle 'EasyGrep'
"Bundle 'matchit.zip'
Bundle 'Mark'
"Bundle 'Conque-Shell'
"Bundle 'FencView.vim'
"Bundle 'Gundo'
"Bundle 'CmdlineComplete'
"filetype plugin indent on

" original repos on github
" githubÉÏµÄÓÃ»§Ð´µÄ²å¼þ£¬Ê¹ÓÃÕâÖÖÓÃ»§Ãû+repoÃû³ÆµÄ·½Ê½
Bundle 'jlanzarotta/bufexplorer'
" Bundle 'tpope/vim-fugitive'
" vim-scripts repos
" vimscriptsµÄrepoÊ¹ÓÃÏÂÃæµÄ¸ñÊ½£¬Ö±½ÓÊÇ²å¼þÃû³Æ
"Bundle 'taglist.vim'
" non github reposo
" ·ÇgithubµÄ²å¼þ£¬¿ÉÒÔÖ±½ÓÊ¹ÓÃÆägitµØÖ·
" Bundle 'git://git.wincent.com/command-t.git'

" Brief help
" :BundleList          - list configured bundles
" :BundleInstall(!)    - install(update) bundles
" :BundleSearch(!) foo - search(or refresh cache first) for foo
" :BundleClean(!)      - confirm(or auto-approve) removal of unused bundles
" vundleÖ÷Òª¾ÍÊÇÉÏÃæÕâ¸öËÄ¸öÃüÁî£¬ÀýÈçBundleInstallÊÇÈ«²¿ÖØÐÂ°²×°£¬BundleInstall!ÔòÊÇ¸üÐÂ
" Ò»°ã°²×°²å¼þµÄÁ÷³ÌÎª£¬ÏÈBundleSearchÒ»¸ö²å¼þ£¬È»ºóÔÚÁÐ±íÖÐÑ¡ÖÐ£¬°´i°²×°
" °²×°ÍêÖ®ºó£¬ÔÚvimrcÖÐ£¬Ìí¼ÓBundle 'XXX'£¬Ê¹µÃbundleÄÜ¹»¼ÓÔØ£¬Õâ¸ö²å¼þ£¬Í¬Ê±Èç¹û
" ÐèÒªÅäÖÃÕâ¸ö²å¼þ£¬Ò²ÊÇÔÚvimrcÖÐÉèÖÃ¼´¿É
" see :h vundle for more details or wiki for FAQ
"}
"===================================================================="
"===================================================================="




"===================================================================="
"====> general settings> {
"===================================================================="
set guitablabel=%N\ %f
"set encoding=utf-8
" for windows vim {
set guifont=Microsoft_YaHei_Mono:h11:cGB2312
set guifont=Consolas:h11:cANSI
"source $VIMRUNTIME/vimrc_example.vim
"source $VIMRUNTIME/mswin.vim
"behave mswin
"}
"let g:solarized_termcolors=256
"let g:solarized_termtrans = 1
color desert

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
"set relativenumber
set nu
set undofile
"=>undo dir, all the un~ files will be saved there
set undodir=$VIMRUNTIME/undo
set undolevels=1000

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

"means line end, line ahead
nmap la 0
nmap le $
nnoremap <leader><space> :noh<cr>
nnoremap <tab> %
vnoremap <tab> %

set nowrap
"set textwidth=79
"set formatoptions=qrn1
"set colorcolumn=138


nnoremap j gj
nnoremap k gk
"insert mode movement
imap <c-k> <up>
imap <c-j> <down>
imap <c-h> <left>
imap <c-l> <right>

",re manually refresh the buffer
nnoremap <leader>re :bufdo e<CR>
"When use (f,F,t,T) to locate a character in a line, ; can be a repeation
"character, so Don't remap this to :
"nnoremap ; :

"ÉèÖÃ¿ì½Ý¼ü½«Ñ¡ÖÐÎÄ±¾¿é¸´ÖÆÖÁÏµÍ³¼ôÌù°å
vnoremap<Leader>y "+y

"ÉèÖÃ¿ì½Ý¼ü½«ÏµÍ³¼ôÌù°åÄÚÈÝÕ³ÌùÖÁvim
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
"nmap <m-j> mz:m+<cr>`z
set <m-k> =k
"nmap <m-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z
" ALT-a means select all
set <m-a> =a
map <m-a> ggVG

" => Visual mode related
" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>

" => vimgrep searching and cope displaying
" When you press gv you vimgrep after the selected text
vnoremap <silent> gv :call VisualSelection('gv')<CR>
" When you press <leader>r you can search and replace the selected text
vnoremap <silent> <leader>r :call VisualSelection('replace')<CR>

"au FocusLost * :wa
"F2 to toggle the paste mode
set pastetoggle=<F2>
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
"===================================================================="
"===================================================================="



"===================================================================="
"====>plugin configuration
"===================================================================="
"==>buf_it settings = {
"=>ctrl+h ctrl+l
"nmap  <C-h>      :call BufPrevPart()<cr>
"nmap  <C-l>      :call BufNextPart()<cr>
"=>close the current buf
"nnoremap <Leader>q  :call BufClose()<CR> 
"=>save and close the current buf
"nnoremap <Leader>wq :w<CR><Esc>:call BufClose()<CR> 
"=>save the current buf
"nnoremap <Leader>w  :w<CR> 
"}


"==>The NERD-Tree settings = {
"nnoremap <leader>n   :NERDTree<cr>
"nnoremap <leader>nb  :Bookmark 
"nnoremap <leader>nob :OpenBookmark 
"nnoremap <leader>N   :NERDTreeClose<cr>         
"let NERDTreeWinPos ="left"                      "½«NERDTreeµÄ´°¿ÚÉèÖÃÔÚgvim´°¿ÚµÄ×ó±ß
"let NERDTreeShowBookmarks=1                     "µ±´ò¿ªNERDTree´°¿ÚÊ±£¬×Ô¶¯ÏÔÊ¾Bookmarks
"let NERDTreeChDirMode=2                         "´ò¿ªÊéÇ©Ê±£¬×Ô¶¯½«VimµÄpwdÉèÎª´ò¿ªµÄÄ¿Â¼£¬Èç¹ûÄãµÄÏîÄ¿ÓÐtagsÎÄ¼þ£¬Äã»á·¢ÏÖÕâ¸öÃüÁîºÜÓÐ°ïÖú
"}


"==>The taglist settings = {
"let Tlist_Use_Right_Window=1
"nmap<Leader>t :TlistToggle<cr>
"}



"==>The supertab settings = {
"filetype plugin indent on
"set completeopt=longest,menu
"let g:SuperTabRetainCompletionType=2
"let g:SuperTabDefaultCompletionType="<C-X><C-O>"
"}


"==>easy motion settings = {
"let g:EasyMotion_leader_key = '<,>'
"}


"==>The FuzzyFinder settings = {
"nnoremap <Leader>ff  :FufFile<cr>
"nnoremap <Leader>fd  :FufDir<cr>
"nnoremap <Leader>fb  :FufBuffer<cr>
"=>ctrl+shift+F would open the all files under the current dir to search
"map <C-S-F> :FufFileRecursive<CR>
"};


"==>The Mark settings = {
nmap <silent> ,hl <Plug>MarkSet
vmap <silent> ,hl <Plug>MarkSet
nmap <silent> ,hh <Plug>MarkClear
vmap <silent> ,hh <Plug>MarkClear
nmap <silent> ,hr <Plug>MarkRegex
vmap <silent> ,hr <Plug>MarkRegex
"}

"==>The EasyGrep settings = {
"<leader>vv- Grep for the word under the cursor
"<leader>va - Like vv, but add to existing list
"<leader>vo - Select the files to search in and set grep options
":Grep SearchString
"map f/ <esc>:Grep
"}


"==>The gundo settings = {
"nnoremap <F11> :GundoToggle<CR>
"nnoremap <F12> :earlier 100000<CR>
"

"==>Ctags settings {
"=>This will look in the current directory for 'tags', and work up the tree towards root until one is found.
"set tags=./tags;/,$HOME/vimtags
"map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR> " C-\ - Open the definition in a new tab
"map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>      " A-] - Open the definition in a vertical split
" }
"===================================================================="
"===================================================================="




"===================================================================="
"====> Helper functions
"===================================================================="
function! CmdLine(str)
    exe "menu Foo.Bar :" . a:str
    emenu Foo.Bar
    unmenu Foo
endfunction

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
"===================================================================="
"===================================================================="
