" The particularly useful features of eclim, bound to hot-keys.

" Handle missing imports
nnoremap <silent> <buffer> <leader>i :JavaImport<cr>

" Create a template in a new buffer for abstract/missing interface methods.
nnoremap <silent> <buffer> <leader>a :JavaImpl<cr>

" Look up the Java(D)oc for the thing under the cursor
nnoremap <silent> <buffer> <leader>d :JavaDocPreview<cr>

" Search
nnoremap <silent> <buffer> <leader>j :JavaSearchContext<cr>

" Reformat text
nnoremap <silent> <buffer> <leader>f :JavaFormat<cr>

" Add getter/setter
nnoremap <silent> <buffer> <leader>g :JavaGet<cr>
nnoremap <silent> <buffer> <leader>s :JavaSet<cr>

""" Some macros of mine to insert things that are handy.
""" These assume eclim is available.


" cleanup and organize imports.
if !exists("*aaron:cleanAndOrganizeImports")
  function! aaron:cleanAndOrganizeImports()
   execute 'set noignorecase'
   execute 'JavaImportOrganize'
   execute 'set ignorecase'
  endfunction
endif

command! -nargs=0 -bar CleanAndOrganizeImports call aaron:cleanAndOrganizeImports()
nnoremap <silent> <buffer> <leader>I :CleanAndOrganizeImports<cr>

" Add a slf4j logger to the current class.
if !exists("*aaron:addlogger")
  function! aaron:addlogger()

    let l = line(".")
    let c = col(".")

    " Get the current filename, chop off the '.java' and everything through the last '/'.
    let filename = expand('%')
    let filename = substitute(filename, "\.java$", "", "g")
    let classname = substitute(filename, "^.*/", "", "g")

    " Ensure that the appropriate classes are imported.
    call eclim#java#import#Import('org.slf4j.Logger')
    call eclim#java#import#Import('org.slf4j.LoggerFactory')

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

" Enable AutoComplPop for popup autocomplete and integrate w/ Eclim's completer function.
" (see http://eclim.org/vim/code_completion.html)
let g:acp_enableAtStartup=0 " Actually, leave this disabled for now.. it has icky bugs.
let g:acp_completeoptPreview=1

let g:acp_behaviorJavaEclimLength = 3
function! MeetsForJavaEclim(context)
  return g:acp_behaviorJavaEclimLength >= 0 &&
        \ a:context =~ '\k\.\k\{' . g:acp_behaviorJavaEclimLength . ',}$'
endfunction
let g:acp_behavior = {
    \ 'java': [{
      \ 'command': "\<c-x>\<c-u>",
      \ 'completefunc' : 'eclim#java#complete#CodeComplete',
      \ 'meets'        : 'MeetsForJavaEclim',
    \ }]
  \ }

"execute 'AcpEnable'

