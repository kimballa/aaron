set nowritebackup
set nobackup
set autoindent
set tabstop=2
set shiftwidth=2
set expandtab
set backspace=eol,indent,start
set whichwrap=b,s,<,>,~,[,]
syntax on
set background=dark
set textwidth=100
"set list
"set listchars=tab:»·,trail:·
set title

set visualbell
set t_vb=
set mouse=a

" Searches: highlight matches, and be case insensitive;
" unless they contain at least one capital letter.
set hlsearch
set ignorecase
set smartcase

" Use these commands if you want the 'j' and 'k' keys to move one screen line instead
" of one <CR>-delimited line at a time.
" :nmap j gj
" :nmap k gk

" Cycle between open buffers
:nmap <C-n> :bnext<CR>
:nmap <C-p> :bprev<CR>
" List buffers
:nmap <C-b> :BuffersToggle<CR>

" Start Pathogen for module loading. Modules live in ~/.vim/bundle/
" https://github.com/tpope/vim-pathogen
execute pathogen#infect()

" Autoclose XML and HTML tags in .xml and .html documents:
" Use CTRL+SHIFT+_ to close it.
au Filetype html,xml,xsl source ~/.vim/plugin/closetag.vim
" In HTML documents, use html-style tag closing by setting a var and reloading:
au Filetype html let b:closetag_html_style=1
au Filetype html source ~/.vim/plugin/closetag.vim

au BufRead,BufNewFile *.scala set filetype=scala
au BufRead,BufNewFile *.scala set syntax=scala

" for eclim
set nocompatible
filetype plugin on
" (aaron) 2020 -- disable Eclim for now.
let g:EclimDisabled = 1
"silent !maybe-start-eclimd&

" Use first level of the package name for grouping in Eclim imports
let g:EclimJavaImportPackageSeparationLevel = 1

" Set up tags like I want them.
" In priority order, search current project, then all source in ~/src.
" Requires my 'gitroot' bash script

" Find the git root, if there is one, and strip any leading/trailing whitespace.
let curGitRoot = system("gitroot")
"/home/aaron/src/git"
let curGitRoot = substitute(curGitRoot, "^\\s\\+", "", "g")
let curGitRoot = substitute(curGitRoot, "[\\s]\\+$", "", "g")
let curGitRoot = substitute(curGitRoot, "\\n", "", "g")
let curGitRoot = substitute(curGitRoot, "\\r", "", "g")

let fullTagList = strlen(curGitRoot) ? curGitRoot . "/tags\\ " .
    \ system("cat " . curGitRoot . "/.taglist") . "\\ ~/src/tags" :
    \ "~/src/git/tags\\ ~/src/tags"
" 'set tags' will tokenize the spaces properly only if we use 'set'.
" Simply doing 'let &tags=...' won't properly pick up multiple tags
" files.
"execute "set tags=" . fullTagList

" For the supertab program, use context completion
let g:SuperTabDefaultCompletionType = "context"

" taglist: display only tags for the current active buffer.
let g:Tlist_Show_One_File = 1

" pop open project tree with F8
nnoremap <silent> <F8> :ProjectTree<CR>

" toggle taglist with F9
nnoremap <silent> <F9> :TlistToggle<CR>

" Functions for making the screen doublewidth or normalwidth
function! AaronDoublewide()
  " 2 100-column windows plus the vertical spacer
  let &columns = 201
endfunction

function! AaronNormalwide()
  let &columns = 100
endfunction

" set to double width, and :vsp the file
function! AaronDoublevsplit(...)
  call AaronDoublewide()
  if a:0 > 0
    execute "vsplit " . a:1
  else
    execute "vsplit"
  endif
endfunction

" Function for turning on "serious mode"
function! AaronSerioushackmode()
  let &columns = 132
  execute "ProjectTree"
  execute "TlistOpen"
endfunction

command! -nargs=0 -bar DoubleWidth call AaronDoublewide()
command! -nargs=0 -bar NormalWidth call AaronNormalwide()
command! -nargs=? -complete=file VSP call AaronDoublevsplit("<args>")
command! -nargs=0 -bar HackMode call AaronSerioushackmode()

" engage hackmode with F4
nnoremap <silent> <F4> :HackMode<CR>

" cycle through tag list with + and _
nnoremap <silent> + :tnext<CR>
nnoremap <silent> _ :tprev<CR>

" set '\o' to run :only
"nnoremap <silent> <Leader>o :only<CR>

" just kidding, set it to toggle paste mode.
nnoremap <silent> <Leader>o :set paste!<CR>

" I never use the 'single-char-replace' function anyway.
nnoremap <silent> r :redo<CR>

" Define a function to count the number of active buffers.
function! NumBufs()
    let i = bufnr('$')
    let j = 0
    while i >= 1
        if buflisted(i)
            let j+=1
        endif
        let i-=1
    endwhile
    return j
endfunction

" A function that will close vim if this is the only visible buffer.
function! AaronCloseIfOnlyErrorBuffer()
  let num_windows=winnr('$')
  if (NumBufs() == 2 && num_windows == 1)
    " All we have is the source file and this error buffer,
    " and the source file is hidden (":q"'d away). Destroy this buffer then attempt to quit
    " the rest. Break if our file is somehow dirty.
    execute "bd"
    execute "qa"
  endif
endfunction
command! -nargs=0 -bar DoNotSaveAndCloseOnlyBuffer call AaronCloseIfOnlyErrorBuffer()


" Open the error-messages window and go to the error message associated
" with the current line.
function! AaronPop_current_error()
  let cur_file_name = expand("%")
  let cur_line_no = line(".")
  execute "lopen"
  execute "silent! /" . cur_file_name . "|" . cur_line_no . " "
  " Register an entry hook such that if this is the only visible buffer, close vim.
  au BufEnter <buffer> DoNotSaveAndCloseOnlyBuffer
endfunction
command! -nargs=0 -bar PopCurError call AaronPop_current_error()
nnoremap <silent> <leader>e :PopCurError<CR>

fun! AaronStripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    let _s = @/
    %s/\s\+$//e
    let @/ = _s
    call cursor(l, c)
endfun
command! -nargs=0 -bar Strip call AaronStripTrailingWhitespaces()


" Disable Eclim XML validation; we never have XSL files handy.
let g:EclimXmlValidate=0
" And for similar reasons, do not update the classpath; user should mvn eclipse:eclipse anyway.
let g:EclimMavenPomClasspathUpdate=0

" Set the preview window to be tiny by default.
set previewheight=2

" Only use AutoComplPop in file types specified by ftplugin/*.vim. Off by default.
let g:acp_enableAtStartup=0
