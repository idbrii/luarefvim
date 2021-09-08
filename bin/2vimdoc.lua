#!/usr/bin/env lua5.3

-- HACK(idbrii): setup input/output
t = io.input("manual.of")
t = io.output("../doc/lua53refvim.txt")

-- special marks:
-- \1 - paragraph (empty line)
-- \4 - remove spaces around it
-- \3 - ref (followed by label|)

---------------------------------------------------------------
header = [[
*luarefvim.txt*        Lua 5.3 Reference Manual for Vim

Adapted from "Lua: 5.3 reference manual"
by R. Ierusalimschy, L. H. de Figueiredo, W. Celes
(c) 2015 Lua.org, PUC-Rio.
]]

footer = [[
==============================================================================
   COPYRIGHT & LICENSES                                        *lrv-copyright*
==============================================================================


This help file has the same copyright and license as Lua 5.3 and the Lua 5.3
manual:

Copyright (C) 1994-2020 Lua.org, PUC-Rio.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

------------------------------------------------------------------------------
 vi:tw=78:ts=4:ft=help:norl:noai
]]

local seefmt = '(see %s)'

if arg[1] == 'port' then
  seefmt = '(ver %s)'
  header = string.gsub(header, "by (.-)\n",
    "%1\n<p>Tradução: Sérgio Queiroz de Medeiros", 1)
  header = string.gsub(header, "Lua (%d+.%d+) Reference Manual",
    "Manual de Referência de Lua %1")
  header = string.gsub(header, "All rights reserved",
    "Todos os direitos reservados")
end


---------------------------------------------------------------

local function compose (f,g)
  assert(f and g)
  return function (s) return g(f(s)) end
end

local function concat (f, g)
  assert(f and g)
  return function (s) return f(s) .. g(s) end
end

local function right_align_line(line)
  local nspaces = 78 - line:len()
  return ('%s%s'):format(string.rep(' ', nspaces), line)
end

local function definition(data)
  local txt = ("*lrv-%s*"):format(data.link)
  txt = right_align_line(txt)
  return txt, data.pretty
end

local function section_label(txt)
  return 'section-'..txt
end

local function code_inline(txt)
  return ("`%s`"):format(txt)
end

local function code(txt)
  return (">%s<"):format(txt)
end

-- Like code(), but adds newlines.
local function code_block(txt)
  return code(("\n  %s\n"):format(txt))
end

local function noop(...)
  return ...
end

local Tag = {
  code = code_inline,
  pre = code,
  verbatim = code,
  --~ a = function(txt, data)
  --~   return ('*%s*'):format(data.link)
  --~ end,
  em = function(txt)
    if txt:match(' ') or not txt:match('[a-z]') then
      return ("'%s'"):format(txt)
    end
    return txt
  end,
  ul = noop,
  li = function(txt)
    return "* ".. txt
  end,
}

Tag.b = Tag.em

setmetatable(Tag, {
    __index = function (t, tag)
      local v = function (n, att)
        local e = ""
        if type(att) == "table" then
          for k,v in pairs(att) do e = string.format('%s %s="%s"', e, k, v) end
        end
        if n then
          return string.format("<%s%s>%s</%s>", tag, e, n, tag)
        else
          return string.format("<%s%s>", tag, e)
        end
      end
      t[tag] = v
      return v
    end
  })



---------------------------------------------------------------
local labels = {}


local function anchor (text, label, link, textlink)
  if labels[label] then
    error("label " .. label .. " already defined")
  end
  labels[label] = {pretty = text, text = textlink, link = link, label = label}
  return definition(labels[label])
end

local function makeref (label)
  assert(not string.find(label, "|"))
  return string.format("\3%s\3", label)
end

local function ref (label)
  local l = labels[label]
  if not l then
    -- Some section names duplicate function names, so have a fallback for
    -- them.
    l = labels[section_label(label)]
  end
  if not l then
    io.stderr:write("label ", label, " undefined\n")
    return "@@@@@@@"
  else
    return ("|lrv-%s|"):format(l.link)
  end
end

---------------------------------------------------------------
local function nopara (t)
  t = string.gsub(t, "\1", "\n\n")
  --~ t = string.gsub(t, "<p>%s*</p>", "")
  return t
end

local function fixpara (t)
  t = string.gsub(t, "\1", "\n")
  --~ t = string.gsub(t, "<p>%s*</p>", "")
  return t
end

local function antipara (t)
  --~ return "</p>\n" .. t .. "<p>"
  return t
end


Tag.pre = compose(Tag.pre, antipara)
Tag.ul = compose(Tag.ul, antipara)

---------------------------------------------------------------
local Gfoots = 0
local footnotes = {}

local line = Tag.hr(nil)

local function dischargefoots ()
  if #footnotes == 0 then return "" end
  local fn = table.concat(footnotes)
  footnotes = {}
  return line .. Tag.h3"footnotes:" .. fn .. line
end


local Glists = 0
local listings = {}

local function dischargelist ()
  if #listings == 0 then return "" end
  local l = listings
  listings = {}
  return line .. table.concat(l, line..line) .. line
end

---------------------------------------------------------------
local counters = {
  h1 = {val = 1},
  h2 = {father = "h1", val = 1},
  h3 = {father = "h2", val = 1},
  listing = {father = "h1", val = 1},
}

local function inccounter (count)
  counters[count].val = counters[count].val + 1
  for c, v in pairs(counters) do
    if v.father == count then v.val = 1 end
  end
end

local function getcounter (count)
  local c = counters[count]
  if c.father then
    return getcounter(c.father) .. "." .. c.val
  else
    return c.val .. ""
  end
end
---------------------------------------------------------------


local function fixed (x)
  return function () return x end
end

local function id (x) return x end


local function prepos (x, y)
  assert(x and y)
  return function (s) return string.format("%s%s%s", x, s, y) end
end


local rw = Tag.b




local function LuaName (name)
  return Tag.code(name)
end


local function getparam (s)
  local i, e = string.find(s, "^[^%s@|]+|")
  if not i then return nil, s
  else return string.sub(s, i, e - 1), string.sub(s, e + 1)
  end
end


local function gettitle (h)
  local title, p = assert(string.match(h, "<title>(.-)</title>()"))
  return title, string.sub(h, p)
end

local function getparamtitle (what, h, nonum)
  local label, title, c, count
  label, h = getparam(h)
  title, h = gettitle(h)
  if not nonum then
    count = getcounter(what)
    inccounter(what)
    c = string.format("%s -- ", count)
  else
    c = ""
  end
  label = label or count
  if label then
    local sec = section_label(label)
    local link,text = anchor(title, label, sec, count)
    title = string.format("%s\n%s%s", link, c, text)
  else
    title = string.format("%s%s", c, title)
  end
  return title, h
end

local function section (what, nonum)
  return function (h)
    local title
    title, h = getparamtitle(what, h, nonum)
    local fn = what == "h1" and dischargefoots() or ""
    return ([[%s~%s%s%s]]):format(title, h, fn, dischargelist())
  end
end


local function verbatim (s)
  s = nopara(s)
  s = string.gsub(s, "\n", "\n  ")
  s = string.gsub(s, "\n%s*$", "\n")
  return Tag.pre(s)
end


local function symbol(s)
  s = s:gsub(" ", "_")
  return ("|lrv-%s|"):format(s)
end

local function verb(s)
  return ("`%s`"):format(s)
end


local function lua2link (e)
  return string.find(e, "luaL?_") and e or "section-"..e
end


local verbfixed = verb


local Tex = {

  ANSI = function (func)
    return "ISO&nbsp;C function " .. Tag.code(func)
  end,
  At = fixed"@",
  B = Tag.b,
  bigskip = fixed"",
  bignum = id,
  C = fixed"",
  Ci = prepos("<!-- ", " -->"),
  CId = function (func)
    return "C&nbsp;function " .. Tag.code(func)
  end,
  chapter = section"h1",
  Char = compose(verbfixed, prepos("'", "'")),
  Cdots = fixed"···",
  Close = fixed"}",
  col = Tag.td,
  defid = function (name)
    local l = lua2link(name)
    -- TODO: Should we use these results?
    local link, text = anchor(name, l, name, name)
    return name
  end,
  def = verb,
  description = compose(nopara, Tag.ul),
  Em = fixed("\4" .. "—" .. "\4"),
  emph = Tag.em,
  emphx = Tag.em,    -- emphasis plus index (if there was an index)
  En = fixed("–"),
  format = fixed"",
  ["false"] = fixed(Tag.b"false"),
  id = Tag.code,
  idx = Tag.code,
  index = fixed"",
  Lidx = fixed"",  -- Tag.code,
  ldots = fixed"...",
  x = id,
  itemize = compose(nopara, Tag.ul),
  leq = fixed"≤",
  Lid = function (s)
    return makeref(s)
  end,
  M = Tag.em,
  N = function (s) return s or (string.gsub(s, " ", "&nbsp;")) end,
  NE = id,        -- tag"foreignphrase",
  num = id,
  ["nil"] = fixed(symbol"nil"),
  fail = fixed(Tag.b"fail"),
  Open = fixed"{",
  part = section("h1", true),
  Pat = compose(verbfixed, prepos("'", "'")),
  preface = section("h1", true),
  psect = section("h2", true),
  Q = prepos('"', '"'),
  refchp = makeref,
  refcode = makeref,
  refsec = makeref,

  pi = fixed"π",
  rep = Tag.em,
  Rw = rw,
  rw = rw,
  sb = Tag.sub,
  sp = Tag.sup,
  St = compose(verbfixed, prepos('"', '"')),
  sect1 = section"h1",
  sect2 = section"h2",
  sect3 = section"h3",
  sect4 = section("h4", true),
  simplesect = id,
  Tab2 = function (s) return Tag.table(s, {border=1}) end,
  row = Tag.tr,
  title = Tag.title,
  todo = Tag.todo,
  ["true"] = fixed(Tag.b"true"),
  T = verb,

  item = function (s)
    local t, p = string.match(s, "^([^\n|]+)|()")
    if t then
      s = string.sub(s, p)
      s = Tag.b(t..": ") .. s
    end
    --~ return Tag.li(fixpara(s))
    return Tag.li(s)
  end,

  verbatim = verbatim,

  manual = id,


  -- for the manual

  link =function (s)
    local l, t = getparam(s)
    assert(l)
    return string.format("%s (%s)", t, makeref(l))
  end,

  see = function (s) return string.format(seefmt, makeref(s)) end,
  See = makeref,
  seeC = function (s)
    return string.format(seefmt, makeref(s))
  end,

  seeF = function (s)
    return string.format(seefmt, makeref(lua2link(s)))
  end,

  APIEntry = function (e)
    local signature, description = string.match(e, "^%s*(.-)%s*|(.*)$")
    local name = string.match(signature, "(luaL?_[%w_]+)%)? +%(") or
    string.match(signature, "luaL?_[%w_]+")
    local link,fn_name = anchor(name, name, name, name)
    local apiicmd, ne = string.match(description, "^(.-</span>)(.*)")
    if apiicmd then
      apiicmd = string.match(apiicmd, '<span class="apii">(.+)</span>')
      if apiicmd then
        apiicmd = ('`%s`'):format(apiicmd)
        apiicmd = right_align_line(apiicmd)
        description = ne
      end
    end
    if not apiicmd then
      apiicmd = ''
    end
    --io.stderr:write(e)
    local txt = ("%s\n%s%s%s"):format(link, code_block(signature), apiicmd, description)
    return txt
  end,

  LibEntry = function (e)
    local signature, name, description
    signature, description = string.match(e, "^(.-)|(.*)$")
    name = string.gsub(signature, " (.+", "")
    local l = lua2link(name)
    local link,text = anchor(name, l, name, Tag.code(name))
    local txt = ("%s\n%s%s"):format(link, code_block(signature), description)
    return txt
  end,

  Produc = compose(nopara, Tag.pre),
  producname = prepos("\t", " ::= "),
  Or = fixed" | ",
  -- TODO(idbrii): bar is wrong
  VerBar = fixed"bar",  -- vertical bar
  OrNL = fixed" | \4",
  bnfNter = prepos("", ""),
  bnfopt = prepos("[", "]"),
  bnfrep = prepos("{", "}"),
  bnfter = compose(Tag.b, prepos("‘", "’")),
  producbody = function (s)
    s = string.gsub(s, "%s+", " ")
    s = string.gsub(s, "\4", "\n\t\t")
    return s
  end,

  apii = function (s)
    local pop,push,err = string.match(s, "^(.-),(.-),(.*)$")
    if pop ~= "?" and string.find(pop, "%W") then
      pop = "(" .. pop .. ")"
    end
    if push ~= "?" and string.find(push, "%W") then
      push = "(" .. push .. ")"
    end
    err = (err == "-") and "–" or Tag.em(err)
    return Tag.span(
      string.format("[-%s, +%s, %s]", pop, push, err),
      {class="apii"}
      )
  end,
}

local others = prepos("?? "," ??")

local function trata (t)
  t = string.gsub(t, "@(%w+)(%b{})", function (w, f)
    f = trata(string.sub(f, 2, -2))
    if type(Tex[w]) ~= "function" then
      io.stderr:write(w .. "\n")
      return others(f)
    else
      return Tex[w](f, w)
    end
  end)
  return t
end


---------------------------------------------------------------------
---------------------------------------------------------------------

-- read whole book
t = io.read"*a"

t = string.gsub(t, "\n\n+", "\1")

-- Make these items jumpable since they're all metatable keys.
t = string.gsub(t, "@item{@idx{(%S-)}", "@LibEntry{%1")



-- complete macros with no arguments
t = string.gsub(t, "(@%w+)([^{%w])", "%1{}%2")

t = trata(t)

-- correct references
t = string.gsub(t, "\3(.-)\3", ref)

-- remove extra space (??)
t = string.gsub(t, "%s*\4%s*", "")

t = nopara(t)

-- TODO: can we avoid inserting these? I think it's from @item
-- Handle weird items with |
t = string.gsub(t, "||", "| ")

io.write(header, t, footer)

