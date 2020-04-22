# go module 初始化

要初始化modules，需要使用如下命令（假设已经安装配置好golang1.11(或者>=1.11)）：

```
go mod init [module name]
```

我们的module叫test，所以就是：

```
go mod init test
```

初始完成后会在目录下生成一个go.mod文件，里面的内容只有：

```go
module test

go 1.13
```



# 包管理

那么我们怎么进行包管理呢？

* 自动更新，使用 `go build，go test以及go list`时，go会自动更新go.mod 文件，将依赖关系写入其中

* 手动处理，使用`go mod tidy`时，会手动处理依赖关系。这条命令会自动更新依赖关系，并且将包下载放入cache。



# 包版本控制

modules同样可以做到对包的版本控制。

## 在介绍版本控制之前，我们要先明确一点

原则：

* 如果 "上层目录和下层目录" 的go.mod里有相同的package规则。
* 那么上层目录的 无条件覆盖 下层目录，目的是为了main module的构建不会被依赖的package所影响。

## 版本示例及解读

那么我们看看go.mod长什么样：

```
module test

require github.com/chromedp/chromedp v0.1.2
```

如果有多个依赖，可以是这样的：

```
module github.com/chromedp/chromedp

require (
	github.com/chromedp/cdproto v0.0.0-20180713053126-e314dc107013
	github.com/disintegration/imaging v1.4.2
	github.com/gorilla/websocket v1.2.0
	github.com/knq/sysutil v0.0.0-20180306023629-0218e141a794
	github.com/mailru/easyjson v0.0.0-20180606163543-3fdea8d05856
	golang.org/x/image v0.0.0-20180708004352-c73c2afc3b81
)
```

前面部分是包的名字，也就是import时需要写的部分，而空格之后的是版本号，版本号遵循如下规律：

```
vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef
vX.0.0-yyyymmddhhmmss-abcdefabcdef
vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef
vX.Y.Z
```

* 格式也就是：`版本号+时间戳+hash`

* 我们自己指定版本时，只需要指定版本号即可。
  * 没有版本tag的，则需要找到对应commit的时间和hash值。
* 默认使用最新版本的package。

## 如何修改依赖版本

现在我们要修改依赖关系了，我们想使用chromedp 的v0.1.0版本，怎么办呢？

第一步：

只需要如下命令，告诉mod管理我们需要的包版本

```
go mod edit -require="github.com/chromedp/chromedp@v0.1.0"
```

@后面加上你需要的版本号。go.mod已经修改了：

```
module test

require github.com/chromedp/chromedp v0.1.0
```

第二步：

我们还需要让go modules更新依赖关系，这里我们手动 `go mod tidy` 命令，之后就会发现 go.sum 文件里的依赖关系链发生了更新，更新为 chromedp v0.1.0 时的依赖关系链了。


