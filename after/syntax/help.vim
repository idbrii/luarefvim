" Help extensions for luarefvim
" This is somewhat based on CRefVim
" Maintainer: Luis Carvalho <lexcarvalho@gmail.com>
" Last Change: May, 26, 2005
" Version: 0.1

" Only apply syntax to our help docs (which are actually lua reference).
if -1 == stridx(expand('%:p'), expand("<sfile>:p:h:h:h") .'/doc/')
    finish
endif

" add three syntax classes: bold, emph (italic) and code -- similarly to html
syn match helpIgnoreBold     "#[a-zA-Z0-9&()\`\'\"\-\+\*=\[\]\{\}\.,;: ]\+#" contains=helpMatchBold
syn match helpMatchBold      "[a-zA-Z0-9&()\`\'\"\-\+\*=\[\]\{\}\.,;: ]\+"   contained
syn match helpIgnoreEmph     "@[a-zA-Z0-9&()\`\'\"\-\+\*=\[\]\{\}\.,;: ]\+@" contains=helpMatchEmph
syn match helpMatchEmph      "[a-zA-Z0-9&()\`\'\"\-\+\*=\[\]\{\}\.,;: ]\+"   contained
" this match is the same as in CRefVim's help.vim (that is, uses $$):
" the idea is to keep some degree of portability.
syn match helpIgnoreCode     "\$[a-zA-Z0-9@\\\*/\._=()\-+%<>&\^|!~\?:,\[\];{}#\`\'\" ]\+\$" contains=helpMatchCode
syn match helpMatchCode      "[a-zA-Z0-9@\\\*/\._=()\-+%<>&\^|!~\?:,\[\];{}#\`\'\" ]\+"   contained

syn clear helpHyperTextJump
" helpHyperTextJump copied from $VIMRUNTIME/ftplugin/help.vim
if has("ebcdic")
    syn match helpHyperTextJump	"\\\@<!|[^"*|]\+|" contains=helpBar,helpHideLrv,helpHideLove
else
    syn match helpHyperTextJump	"\\\@<!|[#-)!+-~]\+|" contains=helpBar,helpHideLrv,helpHideLove
endif
if has("conceal")
    syn match helpHideLrv		contained "\<lrv-" conceal
    syn match helpHideLove		contained "\<love-" conceal
else
    syn match helpHideLrv		contained "\<lrv-"
    syn match helpHideLove		contained "\<love-"
endif

" syn high links
hi def link helpIgnoreBold     Ignore
hi def link helpIgnoreEmph     Ignore
hi def link helpIgnoreCode     Ignore
hi def link helpMatchBold      Function
hi def link helpMatchEmph      Special
hi def link helpMatchCode      Comment
hi def link helpHideLrv        Ignore
