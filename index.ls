fs = require \fs
path = require \path
_ = require \underscore
crypto = require \crypto
ignoreParams = require \./ignore.json

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
console.log path.join pwd, '.gitignore'
# ignore file
ignore = require \ignore
ig = ignore!addIgnoreFile path.join pwd, 'fileccignore'
ignoreParams.push 'filecc-out-*'
ig.addPattern ignoreParams

find pwd, dirHead    # results in fileList, dirHead

originPwd = pwd
pwd = path.join pwd, overwrite!
mkdirsIfNotOverwrite dirHead, pwd

# translate file use OpenCC
Promise.map fileList, (file) ->
  ofilepath = path.join originPwd, file
  nfilepath = path.join pwd, file
  fs.readFileAsync ofilepath
    .then (data) ->
      result = 
        required: false
        data: data
      # temp: binary 判斷
      if (data.toString!) != (new Buffer data.toString!).toString!
        return Promise.resolve result
      data = data.toString 'utf8'
      hash = md5 data
      translateData = opencc.convertSync data
      translateHash = md5 translateData
      
      if hash != translateHash
        result.required = true
        result.data = translateData
      Promise.resolve result
    .then (result) ->
      if result.required || !opts.overwrite
        console.log 'writing file: ' + nfilepath + if result.required then '(changed)' else ''
        fs.writeFileAsync nfilepath, result.data
.then ->
  console.log \end