# go module 进行初始化，生成 go.mod文件
go mod init test

# 查看
.
├── go.mod
└── main.go

# 执行手动处理依赖关系，进行更新依赖包关系，原因：我们本身包需要 github.com/chromedp/chromedp ，而此包 chromedp 内部也有着它需要的一些依赖包。
go mod tidy

# 查看
.
├── go.mod
├── go.sum
└── main.go

# 发现多了一个 go.sum文件，干什么用的？

# 说明：
# 这是我们 "自己的包直接引用的package" 和 "它(被引用的package)自身需要的依赖的版本记录"

# 作用：
# go modules 就是根据这些去找到需要的packages的。

# 顺带一提，如果我们不做任何修改，默认会使用最新的包版本，如果包打过tag，那么就会使用最新的那个tag对应的版本。

# 此处，我们可以编译代码看看效果
go build

# 查看，代码成功构建了，包管理都由 go modules 替我们完成了(而我们并没有下载这些安装包，也没有进行 go install ，这些应该都是在缓存cache中进行的)。
.
├── go.mod
├── go.sum
├── main.go
└── test

# 修改依赖版本号，此时查看 go.mod 中，会发现require的chromedp包版本已经被修改了
go mod edit -require="github.com/chromedp/chromedp@v0.1.0"

# 更新依赖包关系，需要执行命令更新关系链，此时更新成功后，所有的关系链都是 chromedp在v0.1.0时的关系链，执行完毕 go.sum 可以发现版本已经更新
go mod tidy
# go: downloading github.com/chromedp/chromedp v0.1.0
# go: extracting github.com/chromedp/chromedp v0.1.0
# go: downloading github.com/chromedp/cdproto v0.0.0-20180703215205-c125a34ea3b3
# go: downloading github.com/mailru/easyjson v0.0.0-20180606163543-3fdea8d05856
# go: downloading github.com/disintegration/imaging v1.4.2
# go: extracting github.com/chromedp/cdproto v0.0.0-20180703215205-c125a34ea3b3
# go: downloading github.com/knq/sysutil v0.0.0-20180306023629-0218e141a794
# go: downloading github.com/gorilla/websocket v1.2.0
# go: extracting github.com/knq/sysutil v0.0.0-20180306023629-0218e141a794
# go: extracting github.com/mailru/easyjson v0.0.0-20180606163543-3fdea8d05856
# go: extracting github.com/disintegration/imaging v1.4.2
# go: downloading golang.org/x/image v0.0.0-20180628062038-cc896f830ced
# go: extracting github.com/gorilla/websocket v1.2.0
# go: extracting golang.org/x/image v0.0.0-20180628062038-cc896f830ced










