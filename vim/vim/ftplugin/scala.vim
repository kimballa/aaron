au BufRead,BufNewFile *.scala set filetype=scala
au BufRead,BufNewFile *.scala set syntax=scala
au! Syntax scala source ~/.vim/syntax/scala.vim

" Strip trailing whitespace when you save a file.
autocmd BufWritePre *.scala :call aaron:StripTrailingWhitespaces()
