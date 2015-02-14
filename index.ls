fs = require \fs
path = require \path
_ = require \underscore
crypto = require \crypto

Promise = require \bluebird
Promise.promisifyAll fs

isText = require 'istextorbinary' .isTextSync

# args
opts = require \optimist
  .usage 'Usage: $0 --path=[dir] [--overwrite] [--config=[file]]'
  .demand 'path'
  .alias 'p', 'path'
  .alias 'o', 'overwrite'
  .alias 'c', 'config'
  .describe 'p', 'Load a directory'
  .describe 'o', 'Overwirte file\n\t(no set: copy to filecc-out directory)'
  .describe 'c', 'OpenCC config file, default: s2t.json'
  .argv 

OpenCC = require \opencc
opencc = new OpenCC opts.config || \s2t.json

filepath = ->
  opts.path || ''

find = (dir, dirNode) ->
  readdir = if dirNode.parent then path.join pwd, dir else dir
  files = ig.filter fs.readdirSync readdir
  _.each files, (filestr) ->
    p = if dirNode.parent then path.join dir, filestr else filestr
    file = fs.lstatSync path.join pwd, p
    fileList.push p if file.isFile!
    if file.isDirectory!
      node = 
        path: filestr
        children: []
        parent: true
      dirNode.children.push node
      find p, node

overwrite = ->
  if !opts.overwrite
    outdir = 'filecc-out-' + new Date!.getTime!
    fs.mkdirSync path.join pwd, outdir
    return outdir
  ''

mkdirsIfNotOverwrite = (dirNode, parent) ->
  if !opts.overwrite
    md = (dirNode, parent) ->
      _.each dirNode.children, (dir) ->
        p = path.join parent, dir.path
        fs.mkdirSync p
        console.log 'mkdir: ' + p
        md dir, p if dir.children.length
    md dirNode, parent

pwd = './'
pwd = path.join pwd, filepath!

# find method results
fileList = []
dirHead =
  path: pwd
  children: []

# ignore file
ignore = require \ignore
ig = ignore!addIgnoreFile path.join pwd, 'fileccignore'
ig.addPattern [ 'filecc-out-*' ]

find pwd, dirHead    # results in fileList, dirHead

originPwd = pwd
pwd = path.join pwd, overwrite!
mkdirsIfNotOverwrite dirHead, pwd

count = total = 0

# translate file use OpenCC
Promise.map fileList, (file) ->
  ofilepath = path.join originPwd, file
  nfilepath = path.join pwd, file
  fs.readFileAsync ofilepath
    .then (data) ->
      result = 
        required: false
        data: data
      # binary decide
      if !isText file, data
        return Promise.resolve result
      data = data.toString 'utf8'
      translateData = opencc.convertSync data
      if data != translateData
        result.required = true
        result.data = translateData
      Promise.resolve result
    .then (result) ->
      total++
      if result.required || !opts.overwrite
        count++ if result.required
        console.log 'writing file: ' + nfilepath + if result.required then '(changed)' else ''
        fs.writeFileAsync nfilepath, result.data
.then ->
  console.log 'end (changed: %d, total: %d)', count, total