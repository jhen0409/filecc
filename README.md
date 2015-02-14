# filecc
[![NPM version](https://badge.fury.io/js/filecc.png)](https://www.npmjs.com/package/filecc)

目錄底下檔案中文轉換，使用 [OpenCC](https://www.npmjs.com/package/opencc)

### Installation
```
$ npm install -g filecc
```

### Usage
```
$ filecc --path=[dir] [--overwrite] [--config=[file]]

Options:
  -p, --path       Load a directory                                      
  -o, --overwrite  Overwirte file
	(no set: copy to filecc-out directory)
  -c, --config     OpenCC config file, default: s2t.json                 
  --path                                                                   [required]
```

你可以設置叫作 fileccignore 的檔案在轉換目錄底下，此檔案的寫法可以參考 .gitignore，它可以用來 ignore 特定的檔案，而不作轉換。

### LICENSE

MIT