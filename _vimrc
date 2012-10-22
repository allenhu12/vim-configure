""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let $VIM = "/root/.vim/"
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
" �����windows��ʹ�õĻ�������Ϊ 
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
" github�ϵ��û�д�Ĳ����ʹ�������û���+repo���Ƶķ�ʽ
" Bundle 'tpope/vim-fugitive'
" Bundle 'Lokaltog/vim-easymotion'
" Bundle 'rstacruz/sparkup', {'rtp': 'vim/'}
" Bundle 'tpope/vim-rails.git'
" vim-scripts repos
" vimscripts��repoʹ������ĸ�ʽ��ֱ���ǲ������
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
" ��github�Ĳ��������ֱ��ʹ����git��ַ
" Bundle 'git://git.wincent.com/command-t.git'
" ...
 
"
" Brief help
" :BundleList          - list configured bundles
" :BundleInstall(!)    - install(update) bundles
" :BundleSearch(!) foo - search(or refresh cache first) for foo
" :BundleClean(!)      - confirm(or auto-approve) removal of unused bundles
" vundle��Ҫ������������ĸ��������BundleInstall��ȫ�����°�װ��BundleInstall!���Ǹ���
" һ�㰲װ���������Ϊ����BundleSearchһ�������Ȼ�����б���ѡ�У���i��װ
" ��װ��֮����vimrc�У����Bundle 'XXX'��ʹ��bundle�ܹ����أ���������ͬʱ���
" ��Ҫ������������Ҳ����vimrc�����ü���
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

" github�ϵ��û�д�Ĳ����ʹ�������û���+repo���Ƶķ�ʽ
Bundle 'Lokaltog/vim-easymotion'

"��ʽ2��vim-scripts����Ĳֿ⣬ֱ�Ӵ�ֿ������ɡ�
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

"color solarized
color molokai
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
set ruler
set backspace=indent,eol,start
set laststatus=2
set statusline=\ %F%m%r\ \ \ %{getcwd()}%h\ \ \ Line:\ %l/%L:%c
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
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
nnoremap j gj
nnoremap k gk

nnoremap ; :

"���ÿ�ݼ���ѡ���ı��鸴����ϵͳ������
vnoremap<Leader>y "+y

"���ÿ�ݼ���ϵͳ����������ճ����vim
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
nnoremap <Leader>cd :lcd %:p:h<CR> 
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
let NERDTreeWinPos ="left"                      "��NERDTree�Ĵ���������gvim���ڵ����
let NERDTreeShowBookmarks=1                     "����NERDTree����ʱ���Զ���ʾBookmarks
let NERDTreeChDirMode=2                         "����ǩʱ���Զ���Vim��pwd��Ϊ�򿪵�Ŀ¼����������Ŀ��tags�ļ�����ᷢ�����������а���
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
"};
"
"The quickfix settings = {
nmap <silent> F6 :QFix<CR>
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
"}
