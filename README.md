# filecc

目錄底下檔案中文轉換，使用 [OpenCC](https://www.npmjs.com/package/opencc)

### Install
```
npm install -g filecc
```

### Using
```
filecc --path=[dir] [--overwrite]
```

你可以設置叫做 fileccignore 的檔案在轉換目錄底下，這個檔案的寫法可以參考 .gitignore，它可以用來 ignore 特定的檔案，不作轉換。

