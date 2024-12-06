" load db ext passwords from separate file
if filereadable(expand("~/.vim/dbext_passwords.vim"))
      source ~/.vim/dbext_passwords.vim
endif

" vim plug setup
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" copied from vim plug automatic installation: https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation

" Plugins configuration
call plug#begin()
Plug 'tpope/vim-dadbod'
Plug 'kristijanhusak/vim-dadbod-ui'
Plug 'kristijanhusak/vim-dadbod-completion'
Plug 'vim-scripts/dbext.vim'      
call plug#end()



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
