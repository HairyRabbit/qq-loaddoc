###

Get ELM PDF file from gitbook.

###

fs      = require "fs"
request = require "request"
jsdom   = require "jsdom"
jquery  = require "jquery"
moment  = require "moment"

now  = do moment
dfmt = "MMM Do"
path = "https://www.gitbook.com/search?q=" + "Elm"#"java"

log  = (x) -> console.log x;x

link = ($el) ->
  $el
    .find ".book-header a"
    .prop "href"

title = ($el) ->
  $el
    .find "h4"
    .text()
    .trim()

star = ($el) ->
  $el
    .find ".octicon-star"
    .parent()
    .text()
    .trim()

date = ($el) ->
  $el
    .find ".octicon-clock"
    .parent()
    .text()
    .trim()

fmtDate = (d) -> d.replace "on ", ""
diffDate = (d) -> d.diff now, 'month'

isHasStar = (x) -> +x.star isnt 0
isUpdated = (x) ->
  fd = fmtDate x.date
  1 > Math.abs diffDate moment fd, dfmt

getPage = (path) ->
  new Promise (res, rej) ->
    jsdom.env path, (err, window) ->
      return rej err if err
      res jquery window

getFile = (path, filename) ->
  new Promise (res, rej) ->
    request path
      .pipe fs.createWriteStream filename
    do res

collect = ($) -> $(".book").toArray().map (n) ->
  link: link $ n
  title: title $ n
  star: star $ n
  date: date $ n

filter = (arr) -> arr.filter (n) -> isUpdated n


zip = (arr) ->
  [a1, a2] = arr
  out = []
  idx = 0
  while a1[idx]
    out.push [a1[idx], a2[idx]]
    idx++
  out


getDownPath = (arr) ->
  Promise.all [
    arr
  , Promise.all arr.map (n) -> getPage n.link
  ]

trimPromise = (arr) -> arr.map (n) -> Object.assign {}, n[0], pdf: n[1]


tolink = (arr) -> arr.map (n) ->
  Object.assign {}, n,
    pdf:
      n.pdf ".octicon-file-pdf"
        .parent()
        .prop "href"


download = (links) ->
  date = moment().format "MM-DD"
  fs.mkdir date, (err, done) ->
    Promise.all links.map (n) -> getFile n.pdf, "#{date}/#{n.title}.pdf"

done = -> log "Done!"    

main = ->
  getPage path
    .then collect
    .then filter
    .then getDownPath
    .then zip
    .then trimPromise
    .then tolink
    .then download
    .then done
    .catch console.log

do main
