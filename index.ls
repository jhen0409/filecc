fs = require \fs
path = require \path
_ = require \underscore
crypto = require \crypto

Promise = require \bluebird
Promise.promisifyAll fs

OpenCC = require \opencc
opencc = new OpenCC \t2s.json

# args
opts = require(\optimist)
  .usage 'Usage: $0 --path=[dir] [--overwrite]'
  .demand 'path'
  .alias 'p', 'path'
  .alias 'o', 'overwrite'
  .describe 'p', 'Load a directory'
  .describe 'o', 'Overwirte file\n(no set: copy to filecc-out directory)'
  .argv 

md5 = (data) ->
  crypto.createHash 'md5' 
    .update data
    .digest \hex

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
ig = ignore!addIgnoreFile ignore.select [ path.join pwd, '.gitignore' ]
ig.addPattern [ 'filecc-out-*' ]

find pwd, dirHead    # results in fileList, dirHead

pwd = path.join pwd, overwrite!
mkdirsIfNotOverwrite dirHead, pwd

# translate file use OpenCC
Promise.map fileList, (file) ->
  fs.readFileAsync file, 'utf8'
    .then (data) ->
      hash = md5 data
      translateData = opencc.convertSync data
      translateHash = md5 translateData
      result = 
        required: false
        data: data
      if hash != translateHash
        result.required = true
        result.data = translateData
      Promise.resolve result
    .then (result) ->
      if result.required || !opts.overwrite
        console.log 'writing file: ' + (path.join pwd, file) + if result.required then '(changed)' else ''
        fs.writeFileAsync (path.join pwd, file), result.data
.then ->
  console.log \end