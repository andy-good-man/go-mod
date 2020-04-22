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

### 一般解决方案

现在我们要修改依赖关系了，我们想使用chromedp 的v0.1.0版本，怎么办呢？

第一步：

只需要如下命令，告诉mod管理我们需要的包版本

```
go mod edit -require="github.com/chromedp/chromedp@v0.1.0"
```

@后面加上你需要的版本号。

可以看到 go.mod 文件已经修改了：

```
module test

require github.com/chromedp/chromedp v0.1.0
```

第二步：

我们还需要让go modules更新依赖关系，这里我们手动 `go mod tidy` 命令，之后就会发现 go.sum 文件里的依赖关系链发生了更新，更新为 chromedp v0.1.0 时的依赖关系链了。

### 如果没有tag版本号呢？

在上边，我们讨论了版本号遵循的规律：

```
vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef
vX.0.0-yyyymmddhhmmss-abcdefabcdef
vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef
vX.Y.Z
```

在go.mod文件中我们也需要这样指定，否则go mod无法正常工作，这带来了2个痛点：

* 目标库需要打上符合要求的tag，如果tag不符合要求不排除日后出现兼容问题(一般tag就行，特殊情况除外)
* 如果目标库没有打上tag，那么就必须毫无差错的编写大串的版本信息，大大加重了使用者的负担。

如何解决这俩痛点？

基于以上原因，现在可以直接使用`commit的hash`来指定版本，而不是使用版本号`v0.1.0`，如下：

```text
# 使用go get时
go get github.com/mqu/go-notify@ef6f6f49

# 在go.mod中指定
module my-module

require (
  // other packages
  github.com/mqu/go-notify ef6f6f49
)
```

随后我们运行`go build`或`go mod tidy`，这两条命令会整理并更新go.mod文件，更新后的文件会是这样：

```text
module my-module

require (
	github.com/mattn/go-gtk v0.0.0-20181205025739-e9a6766929f6 // indirect
	github.com/mqu/go-notify v0.0.0-20130719194048-ef6f6f49d093
)
```

可以看到hash信息自动扩充成了符合要求的版本信息，今后可以依赖这一特性简化包版本的指定。

**对于hash信息只有两个要求**：

1. 指定hash信息时不要在前面加上`v`，只需要给出commit hash即可
2. hash至少需要8位，与git等工具不同，少于8位会导致go mod无法找到包的对应版本，推荐与go mod保持一致给出12位长度的hash

# replace替换依赖包

`go mod edit -replace`无疑是一个十分强大的命令，但强大的同时它的限制也非常多。

本部分你将看到两个例子，它们分别阐述了本地包替换的方法以及顶层依赖与间接依赖的区别，现在让我们进入第一个例子。

## 特点

replace除了可以将远程的包进行替换外，还可以将本地存在的modules替换成任意指定的名字。

## 准备

假设我们有如下的项目：

```bash
tree my-mod

my-mod
├── go.mod
├── main.go
└── pkg
    ├── go.mod
    └── pkg.go
```

* 其中main.go负责调用`my/example/pkg`中的`Hello`函数，

* `my/example/pkg`显然是个不存在的包，我们将用本地目录的`pkg`包替换它，这是my-mod/main.go：

```golang
package main

import "my/example/pkg"

func main() {
	pkg.Hello()
}
```

我们的pkg/pkg.go相对来说很简单：

```golang
package pkg

import "fmt"

func Hello() {
	fmt.Println("Hello --- this is a test for replace command.")
}
```

## 执行使用

* 重点在于my-mod/go.mod文件，虽然不推荐直接编辑mod文件，但在这个例子中与使用`go mod edit`的效果几乎没有区别，所以你可以尝试自己动手修改my-mod/go.mod：

```text
module my-mod

require my/example/pkg v0.0.0

replace my/example/pkg => ./pkg
```

* 至于pkg/go.mod，使用`go mod init`生成后不用做任何修改，它只是让我们的pkg成为一个module，因为replace的源和目标都只能是go modules。

* 因为被replace的包，首先需要被require（wiki说本地替换不用指定，然而我试了报错），所以在my-mod/go.mod中，我们需要先指定依赖的包(require)，即使它并不存在。
  * 对于一个会被replace的包，如果是用本地的module进行替换，那么**如何指定版本**？
    * 可以指定版本为`v0.0.0`(对于没有使用版本控制的包，只能指定这个版本)。
    * 否则应该和替换包的指定版本一致。

* 再看`replace my/example/pkg => ./pkg`这句，与替换远程包时一样，只是将替换用的包名改为了本地module所在的**绝对或相对路径**。

一切准备就绪，我们运行`go build`，然后项目目录会变成这样：

```bash
tree my-mod

my-mod
├── go.mod
├── main.go
├── my-mod
└── pkg
    ├── go.mod
    └── pkg.go
```

那个叫my-mod的文件就是编译好的程序，我们运行它：

```bash
./my-mod
Hello
```

运行成功，`my/example/pkg`已经替换成了本地的`pkg`。

同时我们注意到，使用本地包进行替换时，并不会生成go.sum所需的信息，所以go.sum文件也没有生成。

本地替换的价值在于，它提供了一种使自动生成的代码进入go modules系统的途径，毕竟不管是go tools还是rpc工具，这些自动生成代码也是项目的一部分，如果不能纳入包管理器的管理范围想必会带来很大的麻烦。

## 替换不起作用？







