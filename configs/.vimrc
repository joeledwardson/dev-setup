" load db ext passwords from separate file
if filereadable(expand("~/.vim/dbext_passwords.vim"))
      source ~/.vim/dbext_passwords.vim
endif

" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

" copied from vim plug automatic installation: https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation

" Plugins configuration
call plug#begin()
Plug 'tpope/vim-dadbod'
Plug 'kristijanhusak/vim-dadbod-ui'
Plug 'kristijanhusak/vim-dadbod-completion'
Plug 'vim-scripts/dbext.vim'      
" Plug 'tpope/vim-commentary'  
Plug 'preservim/nerdcommenter'
Plug 'christoomey/vim-tmux-navigator'
call plug#end()

" default ignore case in search
set ignorecase
" Use spaces instead of tabs
set expandtab
" Set shift width (for > and <) to 2 spaces
set shiftwidth=2
" Set tab width to 2 spaces
set tabstop=2
" Keep selection when indenting in visual mode (commeting as seems to break indenting?)
" vnoremap > >gv
" vnoremap < <gv

" Show line numbers
set number

" Show relative line numbers
set relativenumber

set clipboard=unnamedplus
