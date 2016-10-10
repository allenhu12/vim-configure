
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
"let g:solarized_termcolors=256
"let g:solarized_termtrans = 1
    set bg=dark
    "color solarized
	colo ron
else
    set bg=dark
    color default
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
	    colo desert
		"set mouse=a				"enable mouse
		"set t_Co=256     		"enable 256 colors in terminal
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
set backspace=2			    "enable backspace
set fileencodings=utf-8,gb2312,gbk,gb18030  
set termencoding=utf-8  
set encoding=utf-8 
filetype plugin on				"enable filetype detection





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
Bundle 'vim-airline/vim-airline'
Bundle 'vim-airline/vim-airline-themes'
Bundle 'moll/vim-bbye'
Bundle 'Lokaltog/vim-easymotion'
Bundle 'maxbrunsfeld/vim-yankstack'
" Help will be present at the bottom of the file
Bundle 'scrooloose/nerdcommenter'
Bundle 'scrooloose/nerdtree'
"Bundle 'nelson/cscope_maps'
Bundle 'kien/ctrlp.vim'
Bundle 'trotter/autojump.vim'
"Bundle 'vim-scripts/Marks-Browser'
Bundle 'vim-scripts/Solarized'
"Bundle 'wesleyche/SrcExpl'
Bundle 'AndrewRadev/simple_bookmarks.vim'
Bundle 'ludovicchabant/vim-gutentags'
"Bundle 'tpope/vim-repeat'
Bundle 'amiorin/ctrlp-z'
if (g:iswindows)
    Bundle 'vim-scripts/Solarized'
endif
""¸ñÊ½2£ºvim-scriptsÀïÃæµÄ²Ö¿â£¬Ö±½Ó´ò²Ö¿âÃû¼´¿É¡£
"Bundle 'CSApprox'
"Bundle 'L9'
"Bundle 'FuzzyFinder'
"Bundle 'The-NERD-tree'
""the buf_it.vim under e:/program files/vim/plugin is used, it is specially customized, we igore the git buf_it here
""Bundle 'buf_it'
Bundle 'taglist.vim'
"Bundle 'SuperTab'
"Bundle 'ingo-library'
"Bundle 'EnhancedJumps'
Bundle 'EasyGrep'
"Bundle 'matchit.zip'
Bundle 'Mark'
"Bundle 'Conque-Shell'
"Bundle 'FencView.vim'
Bundle 'Gundo'
Bundle 'rking/ag.vim'
"Bundle 'vim-scripts/YankRing.vim'
"Bundle 'CmdlineComplete'
"filetype plugin indent on

" original repos on github
" githubÉÏµÄÓÃ»§Ð´µÄ²å¼þ£¬Ê¹ÓÃÕâÖÖÓÃ»§Ãû+repoÃû³ÆµÄ·½Ê½
Bundle 'jlanzarotta/bufexplorer'
"Bundle 'milkypostman/vim-togglelist'
Bundle 'yegappan/mru'
"Bundle 'tomasr/molokai'
"the help on vim-surround will be presented on the bottom of the file
Bundle 'tpope/vim-surround'
" Bundle 'tpope/vim-fugitive'
Bundle 'jceb/vim-editqf'
" vim-scripts repos
" vimscriptsµÄrepoÊ¹ÓÃÏÂÃæµÄ¸ñÊ½£¬Ö±½ÓÊÇ²å¼þÃû³Æ
"Bundle 'taglist.vim'
" non github reposo
" ·ÇgithubµÄ²å¼þ£¬¿ÉÒÔÖ±½ÓÊ¹ÓÃÆägitµØÖ·


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

" make clipboard accessable by windows applications, windows should run xming and configure secureCRT or putty
set clipboard=unnamed
set confirm
set tabstop=4
set shiftwidth=4
set softtabstop=4
" switch tab back when processing the makefile
autocmd FileType make setlocal noexpandtab
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
if (g:iswindows)
    let s:undodir="$VIMRUNTIME/undo"
    set undodir=$VIMRUNTIME/undo
elseif (g:ismac)
    let s:undodir="/Users/Hubo/.vim/undo"
    set undodir=/Users/Hubo/.vim/undo
elseif (g:islinux)
    let s:undodir="/home/allen.hu/.vim/undo"
    set undodir=~/.vim/undo
endif

if !isdirectory(s:undodir)
call mkdir(s:undodir, "p")
endif

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
set statusline +=%2*0x%04B\ %*          "character under cursor
set laststatus=2
"Set to auto read when a file is changed from the outside
set autoread
set tags=tags;
"means line end, line ahead
"nmap la 0
"nmap le $
nnoremap <leader><space> :noh<cr>
"don't map the tab, because tab equals to ctrl+I
"nnoremap <tab> %
"vnoremap <tab> %

set nowrap
"set textwidth=79
"set formatoptions=qrn1
"set colorcolumn=138

nnoremap j gj
nnoremap k gk
"insert mode movement
"imap <c-k> <up>
"imap <c-j> <down>
""=> if this make backspace invalid, please check the securecrt or xshell keymap setting
"imap <c-h> <left>
"imap <c-l> <right>

",re manually refresh the buffer
nnoremap <leader>re :bufdo e<CR>
"When use (f,F,t,T) to locate a character in a line, ; can be a repeation
"character, so Don't remap this to :
nnoremap ; :
inoremap jj <Esc>
"insert mode with rr will toggle paste
inoremap <C-r> <C-r><C-p>
"insert mode with oo will toggle normal mode
"inoremap oo <C-o>  don't map this because often times we should type oo in
"insert mode
" Use ctrl-[hjkl] to select the active split!
nmap <silent> <c-k> :wincmd k<CR>
nmap <silent> <c-j> :wincmd j<CR>
nmap <silent> <c-h> :wincmd h<CR>
nmap <silent> <c-l> :wincmd l<CR>

"ÉèÖÃ¿ì½Ý¼ü½«Ñ¡ÖÐÎÄ±¾¿é¸´ÖÆÖÁÏµÍ³¼ôÌù°å
vnoremap<Leader>y "+y
"Cut to system clipboard
vnoremap<Leader>d "+d
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
nnoremap <Leader>cd :lcd %:p:h<CR> 

" Move a line of text using ALT+[jk] or Comamnd+[jk] on mac
" to map ALT-j, you have to use set <m-j> =ctrl-v + alt-j
set <m-j> =j
vmap <m-j> mz:m+<cr>`z
set <m-k> =k
vmap <m-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z
" ALT-a means select all
set <m-a> =a
map <m-a> ggVG

"<leader>b, add the ${}around the word
map <leader>b wbi${<Esc>ea}<Esc>
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
" make global marks easier
nmap mm mM
" make jump back to global marks easier
nmap mmm `M
" make the recording easier
" use qq to start the recorder, then 3rd q to complete
" use qa to replay the recorder
nmap qa @q

" 100[m will jump to the beginning of the C function 
nmap [[ 99[m
"au FocusLost * :wa
"F2 to toggle the paste mode
"please manually type ':set paste' to toggle this'
set pastetoggle=<F2>
inoremap <C-r> <C-r><C-p>
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
"===================================================================="
"===================================================================="



"===================================================================="
"====>plugin configuration
"===================================================================="
if executable('ag')
  " Use ag over grep
  set grepprg=ag\ --nogroup\ --nocolor

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
endif
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

"==>The BufExplorer = {
map <C-\> :ToggleBufExplorer<CR> 
"} 

"==>The NERD-Tree settings = {
nnoremap <leader>n   :NERDTree<cr>
nnoremap <leader>nb  :Bookmark 
nnoremap <leader>nob :OpenBookmark 
nnoremap <leader>N   :NERDTreeClose<cr>         
let NERDTreeWinPos ="left"                      "½«NERDTreeµÄ´°¿ÚÉèÖÃÔÚgvim´°¿ÚµÄ×ó±ß
let NERDTreeShowBookmarks=1                     "µ±´ò¿ªNERDTree´°¿ÚÊ±£¬×Ô¶¯ÏÔÊ¾Bookmarks
let NERDTreeChDirMode=2                         "´ò¿ªÊéÇ©Ê±£¬×Ô¶¯½«VimµÄpwdÉèÎª´ò¿ªµÄÄ¿Â¼£¬Èç¹ûÄãµÄÏîÄ¿ÓÐtagsÎÄ¼þ£¬Äã»á·¢ÏÖÕâ¸öÃüÁîºÜÓÐ°ïÖú
nnoremap <F7> :NERDTreeToggle<CR>
"}


"==>The taglist settings = {
"let Tlist_Use_Right_Window=0
nnoremap <leader>t :TlistToggle<cr>
nnoremap <F6> :TlistToggle<CR>
let Tlist_WinWidth = 50
autocmd FileType qf wincmd J
"}



"==>The supertab settings = {
"filetype plugin indent on
"set completeopt=longest,menu
"let g:SuperTabRetainCompletionType=2
"let g:SuperTabDefaultCompletionType="<C-X><C-O>"
"}


"==>easy motion settings = {
"let g:EasyMotion_leader_key = '<,>'
nmap <c-f> <leader><leader>s
"}


"==>The FuzzyFinder settings = {
"nnoremap <Leader>ff  :FufFile<cr>
"nnoremap <Leader>fd  :FufDir<cr>
"nnoremap <Leader>fb  :FufBuffer<cr>
"=>ctrl+shift+F would open the all files under the current dir to search
"map <C-S-F> :FufFileRecursive<CR>
"};

"==>The bufexplorer settings = {
nnoremap <silent> <F10> :bn<CR>
nnoremap <silent> <F9> :bp<CR>
"}

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
":Grep string\C for case sensitive
" map f/ <esc>:Grep 
map f/ <esc>:exec("Ag ".expand("<cword>"))<CR>
map fb/ <esc>:exec("Bgrep ".expand("<cword>"))<CR>

"}


"==>The gundo settings = {
nnoremap <F11> :GundoToggle<CR>
nnoremap <F12> :earlier 100000<CR>
"

"==>Ctags settings {
"=>This will look in the current directory for 'tags', and work up the tree towards root until one is found.
set tags=./tags;/,$HOME/vimtags
"map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR> " C-\ - Open the definition in a new tab
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>      " A-] - Open the definition in a vertical split
" }

"==>ToogleList Settings{
nmap <script> <silent> <leader>l :call ToggleLocationList()<CR>
nmap <script> <silent> <leader>q :call ToggleQuickfixList()<CR>
"}

"==>Ctrlp settings{
 let g:ctrlp_max_files = 80000
 let g:ctrlp_max_depth = 80
 let g:ctrlp_working_path_mode = ''
 "map <C-\> :CtrlPBuffer<CR>
 nmap <leader>sb :CtrlPBuffer<CR>
 let g:ctrlp_extensions = ['tag', 'buffertag', 'quickfix', 'dir', 'rtscript',
                          \ 'undo', 'line', 'changes', 'mixed', 'bookmarkdir']
 let g:ctrlp_custom_ignore = '\v[\/](build|target|dist)|(\.(swp|ico|git|svn))$'
"}

"==>YankRing Settings{
"if !exists('g:yankring_replace_n_pkey')
"   let g:yankring_replace_n_pkey = '<C-Y>'
"endif
"nmap <C-e> :YRShow<CR>
"imap <C-e> <ESC>:YRShow<CR>
"}

"==>YankStack Settings{
nmap <leader>p <Plug>yankstack_substitute_older_paste
nmap <C-e> ,p
imap <C-e> <c-o>,p
"}


"==>bbye Settings{
nnoremap <C-x> :Bdelete<CR>
"}

"==> Source Explorer {
" // The switch of the Source Explorer
nmap <F8> :SrcExplToggle<CR>
" // Set the height of Source Explorer window
let g:SrcExpl_winHeight = 12
" // Set 100 ms for refreshing the Source Explorer
let g:SrcExpl_refreshTime = 100
" // Set "Enter" key to jump into the exact definition context
" let g:SrcExpl_jumpKey = "<ENTER>"
" // Set "Space" key for back from the definition context
let g:SrcExpl_gobackKey = "<SPACE>"
" // In order to Avoid conflicts, the Source Explorer should know what plugins
" // are using buffers. And you need add their bufname into the list below
" // according to the command ":buffers!"
let g:SrcExpl_pluginList = [
        \ "__Tag_List__",
        \ "_NERD_tree_",
        \ "Source_Explorer"
    \ ]
" // Enable/Disable the local definition searching, and note that this is not
" // guaranteed to work, the Source Explorer doesn't check the syntax for now.
" // It only searches for a match with the keyword according to command 'gd'
let g:SrcExpl_searchLocalDef = 1
" // Do not let the Source Explorer update the tags file when opening
let g:SrcExpl_isUpdateTags = 0
" // Use 'Exuberant Ctags' with '--sort=foldcase -R .' or '-L cscope.files' to
" //  create/update a tags file
let g:SrcExpl_updateTagsCmd = "ctags --sort=foldcase -R ."
" // Set "<F9>" key for updating the tags file artificially
let g:SrcExpl_updateTagsKey = "<F9>"
"}

"==> airline {
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline_theme='base16_solarized'
let g:airline#extensions#tabline#buffer_idx_mode = 1

nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9
"}

"==>simple_bookmark {
nmap <leader>bm :Bookmark 
nmap <leader>dm :DelBookmark  
nmap <leader>gm :GotoBookmark
nmap <leader>sm :CopenBookmarks<CR>
"}

"==>vim-gutentags {
" touch the file under the directory that you want to create the ctags 
" it means that the directory will be treated as the gutentags project root
" and then the ctags will be updated automatically when src file changes
let g:gutentags_project_root = ['tagsh']
"}
"
"==>ctrlp-z {
"let g:ctrlp_z_nerdtree=1
let g:ctrlp_extensions = ['Z', 'F']
nnoremap ff :CtrlPZ<Cr>
"}
"
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




function! GetBufferList()
  redir =>buflist
  silent! ls!
  redir END
  return buflist
endfunction

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
nmap <leader>q :QFix<CR>



function! GotoJump()
  jumps
  let j = input("Please select your jump: ")
  if j != ''
    let pattern = '\v\c^\+'
    if j =~ pattern
      let j = substitute(j, pattern, '', 'g')
      execute "normal " . j . "\<c-i>"
    else
      execute "normal " . j . "\<c-o>"
    endif
  endif
endfunction
nmap <Leader>j :call GotoJump()<CR>



nnoremap <F1> :call ToggleVimReference()<CR>
let g:vim_reference_file = "~/workspace/git-depot/vim-conf/_vimrc"
let g:vim_reference_width = 85

function! ToggleVimReference()
    if !exists("s:vim_reference_open") || s:vim_reference_open == 0
        let s:vim_reference_open = 1
        execute "botright vnew " . g:vim_reference_file
        execute "vertical resize " . g:vim_reference_width
		"after open the reference file, simulate a keystroke 'G' to jump
		normal G
    else
        update
        execute "bdelete "  g:vim_reference_file
        let s:vim_reference_open = 0
    endif
endfunction
""
"nnoremap <silent> <Tab> :call SwitchToNextBuffer(1)<CR>
"nnoremap <silent> <S-Tab> :call SwitchToNextBuffer(-1)<CR>

"function! SwitchToNextBuffer(incr)
"let help_buffer = (&filetype == 'help')
"let current = bufnr("%")
"let last = bufnr("$")
"let new = current + a:incr
"while 1
	"if new != 0 && bufexists(new) && ((getbufvar(new, "&filetype") == 'help') == help_buffer)
		"execute ":buffer ".new
			"break
	"else
		"let new = new + a:incr
			"if new < 1
				"let new = last
			"elseif new > last
				"let new = 1
			"endif
			"if new == current
			  "break
			"endif
	"endif 
"endwhile
"endfunction

"let g:airline_detect_modified = 0 "if you're sticking the + in section_c you probably want to disable detection
"function! AirlineInit()
    ""let g:airline_section_a = airline#section#create(['mode', ' ', '%{getcwd()}'])
	"call airline#parts#define_raw('modified', '%{&modified ? "[+]" : ""}')
	"call airline#parts#define_accent('modified', 'red')
	"let g:airline_section_c = airline#section#create(['%f', 'modified', ' ASCII=\%03.3b', ' HEX=\%02.2B'])
	""don't show section y
	"let g:airline_section_y = airline#section#create_right([])
"endfunction
""autocmd User AirlineAfterInit call AirlineInit()
"autocmd VimEnter * call AirlineInit()

"===================================================================="
"===================================================================="
set nocompatible

"===================================================================="
"====> Examples
"===================================================================="
"====================================================================
"edit quickfix window
"in quickfix, type "i" to the insert mode and modify the buffer
"use the command :QFSave to save the the quickfix content to a 
"specified folder. For example, :QFSave ~/quickfix/quickfix_sample.txt
"use the command :QFLoad to load the quickfix file.
"For example, :QFLoad ~/quickfix/quickfix_sample.txt and then trigger
"the quickfix window by <leader>q


"===================================================================="
" vim-surround
" Add a suround [
"		visual select the text, then "S", then "]", will add a "[]" without space
"                                         then "[", will add a "[]" with space
" Del a surround [
"       move into the surrounding, then "ds[", will delete the "[]"
" 
" Change a surround from [ to {
"       move into the surrounding, then "cs[{", will change the surrounding
"===================================================================="

"===================================================================="
" NertComment
" comment the codes (one or multiple lines)
"	visual select the codes, then <leader>cm for multiple lines or <leader>cc
"	for single lines
" uncomment the codes (one or multiple lines)
"	visual select the commentted codes, then <leader>c[space]
"===================================================================="

"±à¼­Ä£Ê½ÏÂscroll:
"¿ÉÒÔÔÚ²»¸Ä±ä¹â±êµÄÇé¿öÏÂ¹ö¶¯£º
"ÔÚ±à¼­Ä£Ê½ÏÂ£ºctrl+o ½øÈënormal, È»ºó zt : ÏòÏÂ·­Ò³£¬zb:ÏòÉÏ·­Ò³
"
"»òÕßÏÈ½øÈënormal mode, È»ºójumpµ½ÏëÈ¥µÄµØ·½£¬²é¿´ºóÓÃgiÌø×ª»ØÀ´
"
"´úÂëÕÛµþ(folding):
"visual modeÑ¡ÖÐÐèÒªÕÛµþµÄ´úÂë£¬È»ºózf
"ÒªÕ¹¿ª£ºza (zaÊÇÒ»¸ötoggleÃüÁî) 
"
"
"nmap <leader>bm :Bookmark 
"nmap <leader>dm :DelBookmark  
"nmap <leader>gm :GotoBookmark <TAB-completed>
"nmap <leader>sm :CopenBookmarks<CR>
"
"=====================================================================:
"²éÕÒÌæ»»: :%substitute/Professor/Teacher/[g/c/p]
"°ÑProfessorÌæ»»³ÉTeacher,%±íÊ¾È«ÎÄ²éÕÒ£¬g±íÊ¾È«¾ÖÌæ»»£¬c±íÊ¾ÒªÇóÈ·ÈÏ£¬p±íÊ¾
"Ñ¡ÖÐÌæ»»£ºÏÈÓÃvÃüÁî½øÈëÑ¡ÖÐÄ£Ê½£¬Ñ¡ÖÐÒªÌæ»»µÄÎÄ±¾¿é£¬È»ºó°´:»á³öÏÖ:'<,>'
"Ö±½ÓÔÚºóÃæ¼ÓsÃüÁî½øÐÐÌæ»»
"
