# KittyTorrents-Archive

#### 介绍
A Simple web crawler for TorrentKitty :)

#### 软件架构
由类KittyTorrents::Archive和命令行脚本kta组成，100%Raku语言编写。HTTP::Tinyish负责发送http请求，HTML::Parser::XML和XML::Query解析页面，
DB::SQLite存储数据到本地SQLite文件，Logger负责日志记录,Terminal::Spinners显示处理进度。


#### 安装教程

```
zef install https://github.com/skyter10086/KittyTorrents-Archive.git
kta --start=2025-01-01 --end=2025-01-03 
tail -f test.log
```

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
