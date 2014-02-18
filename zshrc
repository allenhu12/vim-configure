# PATH=$PATH:/home/allen.hu/user_bin/bin:/home/allen.hu/bin:/home/allen.hu/bin/p4v/bin:/usr/kerberos/bin:/usr/local/bin:/bin:/usr/bin:/usr/sbin:/usr/local/apache-ant-1.7.0/bin:/home/allen.hu/p4v/bin:/home/allen.hu/scripts:/home/allen.hu/local/bin
 PATH=/home/allen.hu/user_bin/bin:/home/allen.hu/bin:/home/allen.hu/bin/p4v/bin:/usr/kerberos/bin:/usr/local/bin:/bin:/usr/bin:/usr/sbin:/usr/local/apache-ant-1.7.0/bin:/home/allen.hu/p4v/bin:/home/allen.hu/scripts:/home/allen.hu/local/bin:$PATH
  
  export PATH
  export P4PORT=perforce.tw.video54.local:1666
  export P4USER=allen.hu
  export P4CLIENT=ALLEN_WORKSPACE
  export P4PASSWD=4alle$1234
  export MY_VIM_PATH=/home/allen.hu/workspace/git-depot/vim-conf/

  # shell support color, "security" should option->session option->emulation->ANSI color checked, use color scheme checked
 TERM=xterm-color
 export TERM

autoload colors
colors

autoload -Uz compinit
compinit

setopt AUTO_LIST
setopt AUTO_MENU
setopt MENU_COMPLETE

setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

case $TERM in
    screen*)
        function sctitle() { print -Pn "\ek$1\e\\"}
        function precmd() { sctitle "%20< ..<%~%<<" }
        function preexec() { sctitle "%20>..>$1%< <" }
        export PS1="%{${fg[cyan]}%}[%D{%H:%M} %20<..<%~%<<]%{$reset_color%} "
    ;;
    *)
        export PS1="%{${fg[cyan]}%}[%D{%H:%M} %n@%m:%20<..<%~%<<]%{$reset_color%} "
    ;;
esac

# number of lines kept in history
export HISTSIZE=10000
# # number of lines saved in the history after logout
export SAVEHIST=10000
# # location of history
export HISTFILE=~/.zhistory
# # append command to history file once executed
setopt INC_APPEND_HISTORY

#Disable core dumps
#limit coredumpsize 0

#Emacs?????
bindkey -e
#??DEL??????
bindkey "\e[3~" delete-char

#????????????
WORDCHARS='*?_-[]~=&;!#$%^(){}<>'

#??????
setopt AUTO_LIST
setopt AUTO_MENU
setopt MENU_COMPLETE

autoload -U compinit
compinit

# Completion caching
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path .zcache
#zstyle ':completion:*:cd:*' ignore-parents parent pwd

#启用 cd 命令的历史纪录，cd -[TAB]进入历史路径
setopt AUTO_PUSHD
#相同的历史路径只保留一个
setopt PUSHD_IGNORE_DUPS


#Completion Options
zstyle ':completion:*:match:*' original only
zstyle ':completion::prefix-1:*' completer _complete
zstyle ':completion:predict:*' completer _complete
zstyle ':completion:incremental:*' completer _complete _correct
zstyle ':completion:*' completer _complete _prefix _correct _prefix _match _approximate

# Path Expansion
zstyle ':completion:*' expand 'yes'
zstyle ':completion:*' squeeze-shlashes 'yes'
zstyle ':completion::complete:*' '\\'

zstyle ':completion:*:*:*:default' menu yes select
zstyle ':completion:*:*:default' force-list always

# GNU Colors ??/etc/DIR_COLORS?? ?????????????????????(?????LS_COLORS)
[ -f /etc/DIR_COLORS ] && eval $(dircolors -b /etc/DIR_COLORS)
    export ZLSCOLORS="${LS_COLORS}"
    zmodload zsh/complist
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

    zstyle ':completion:*' completer _complete _match _approximate
    zstyle ':completion:*:match:*' original only
    zstyle ':completion:*:approximate:*' max-errors 1 numeric

    compdef pkill=kill
    compdef pkill=killall
    zstyle ':completion:*:*:kill:*' menu yes select
    zstyle ':completion:*:processes' command 'ps -au$USER'

# Group matches and Describe
    zstyle ':completion:*:matches' group 'yes'
    zstyle ':completion:*:options' description 'yes'
    zstyle ':completion:*:options' auto-description '%d'
    zstyle ':completion:*:descriptions' format $'\e[01;33m -- %d --\e[0m'
    zstyle ':completion:*:messages' format $'\e[01;35m -- %d --\e[0m'
    zstyle ':completion:*:warnings' format $'\e[01;31m -- No Matches Found --\e[0m'

#????
    alias cp='cp -i'
    alias mv='mv -i'
    alias rm='rm -i'
    alias jj='j'
#alias ls='ls -F --color=auto'
    alias ls='ls -h --color=tty'
    alias ll='ls -l'
    alias grep='grep --color=auto'
    alias ee='emacsclient -t'
    alias vim='/home/allen.hu/user_bin/bin/vim'
#???? ?????????? cd ~xxx
    hash -d WWW="/home/lighttpd/html"
    hash -d ARCH="/mnt/arch"
    hash -d PKG="/var/cache/pacman/pkg"
    hash -d E="/etc/env.d"
    hash -d C="/etc/conf.d"
    hash -d I="/etc/rc.d"
    hash -d X="/etc/X11"
    hash -d BK="/home/r00t/config_bak"

##for Emacs?Emacs?????Zsh????? ????Emacs????
    if [[ "$TERM" == "dumb" ]]; then
    setopt No_zle
    PROMPT='%n@%M %/
    >>'
    alias ls='ls -F'
    fi


    setopt extended_glob
    preexec () {
	    if [[ "$TERM" == "screen" ]]; then
		    local CMD=${1[(wr)^(*=*|sudo|-*)]}
	        echo -n "\ek$CMD\e\\"
		        fi
    }

#
PROMPT="%{$fg_bold[blue]%}%n %{${fg_bold[red]}%}:: %{${fg[green]}%}%3~%(0?. . ${fg[red]}%? )%{${fg[blue]}%}??%{${reset_color}%} "

case $TERM in
screen*)
function sctitle() { print -Pn "\ek$1\e\\"}
function precmd() { sctitle "%20< ..<%~%<<" }
function preexec() { sctitle "%20>..>$1%< <" }
export PS1="%{${fg[cyan]}%}[%D{%H:%M} %20<..<%~%<<]%{$reset_color%} "
;;
*)
export PS1="%{${fg[cyan]}%}[%D{%H:%M} %n@%m:%20<..<%~%<<]%{$reset_color%} "
;;
esac
 # configuration for the vi mode in the zsh shell = {                                                                                      
  #set -o vi                                                                                                                                 
  bindkey '^R' history-incremental-search-backward                                                                                          
  # use vi mode under shell}
[[ -s /home/allen.hu/.autojump/etc/profile.d/autojump.zsh ]] && source /home/allen.hu/.autojump/etc/profile.d/autojump.zsh
autoload -U compinit && compinit -u
