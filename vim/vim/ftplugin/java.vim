""" Some macros of mine to insert things that are handy.

" Add a slf4j logger to the current class.
if !exists("*aaron:addlogger")
  function! aaron:addlogger()

    let l = line(".")
    let c = col(".")

    " Get the current filename, chop off the '.java' and everything through the last '/'.
    let filename = expand('%')
    let filename = substitute(filename, "\.java$", "", "g")
    let classname = substitute(filename, "^.*/", "", "g")

    " Move to the line immediately following the class definition.
    execute '1'
    execute '/class ' . classname
"    execute '/{'
"    execute '-'

    " Insert the log definition.
    if strlen(classname) > 10
      let logstr = '  private static final Logger LOG = LoggerFactory.getLogger('
          \ . "\n" . '      ' . classname . '.class.getName());' . "\n"
    else
      let logstr = '  private static final Logger LOG = LoggerFactory.getLogger('
          \ . classname . '.class.getName());' . "\n"
    endif
    put=logstr

    call cursor(l, c)
  endfunction
endif

command! -nargs=0 -bar AddLogger call aaron:addlogger()
nnoremap <silent> <buffer> <leader>L :AddLogger<cr>


" Creates a new buffer and dumps an equals() method for the current class
" into it. Checks class type, referential equality on all fields, etc.
if !exists("*aaron:addequals")
  function! aaron:addequals()

    " Get the current filename, chop off the '.java' and everything through the last '/'.
    " That's our class name.
    let filename = expand('%')
    let filename = substitute(filename, "\.java$", "", "g")
    let className = substitute(filename, "^.*/", "", "g")

    " Create a new temporary buffer.
    execute 'new'
    set buftype=nofile
    set bufhidden=hide
    setlocal noswapfile

"    search("private .*", "w")

    let body = "  @Override\n"
    let body = body . "  public boolean equals(Object otherObj) {\n"
    let body = body . "    if (otherObj == this) {\n"
    let body = body . "      return true;\n"
    let body = body . "    } else if (null == otherObj) {\n"
    let body = body . "      return false;\n"
    let body = body . "    } else if (!otherObj.getClass().equals(getClass())) {\n"
    let body = body . "      return false;\n"
    let body = body . "    }\n"
    let body = body . "    " . className . " other = (" . className . ") otherObj;\n"
    let body = body . "    // TODO: Add per-field tests here.\n"
    let body = body . "    return true;\n"
    let body = body . "  }\n"
    put=body
  endfunction
endif

command! -nargs=0 -bar AddEquals call aaron:addequals()
nnoremap <silent> <buffer> <leader>E :AddEquals<cr>

" Strip trailing whitespace when you save a file.
autocmd BufWritePre *.java :call aaron:StripTrailingWhitespaces()

" In Java source files, show the tag under the current cursor if the user types \]
fun! aaron:ShowCurrentTagSignature()
  execute "silent! ptag " . expand("<cword>")
endfun
command! -nargs=0 -bar Signature call aaron:ShowCurrentTagSignature()
nnoremap <silent> <leader>] :Signature<CR>

" ... or activate it if the user idles the cursor for 4 seconds.
"au! CursorHold *.java nested exe "silent! ptag " . expand("<cword>")

