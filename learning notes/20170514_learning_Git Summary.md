#Git学习总结
Git 是一种免费且开源的分布式版本控制系统，其可以高效且快速得管理很小或很大的工程。Git 简单易学，占用空间小但性能极好。他拥有远远超过其他诸如 Subversion 、CVS 、Perforce 、ClearCase 等 SCM 工具的特性。这些特性有简易的本地分支、方便的管理策略和多工作流等。

> SCM（Software Configuration Management，软件配置管理）是一种标识、组织和控制修改的技术软件。配置管理是指通过执行版本控制、变更控制的规程，以及使用合适的配置管理软件，来保证所有配置项的完整性和可跟踪性。

## Git 命令
git init //初始化库

git add [file name] //将文件加入暂存区

```
git add test.m
git add *.m //将当前目录下的匹配的文件加入暂存区
git add '*.m' //将整个库中匹配的文件加入暂存区
```

git commit -m "[comment message]" //将暂存区的文件提交到本地库中

git status //查看当前库的状态

git diff [file name] //查看文件修改的地方

git log //查看使用的 Git 命令

git log --pretty=oneline //查看日志，单行显示

```
HEAD 表示当前版本
HEAD^ 表示上一个版本
HEAD^^ 表示上上个版本
HEAD~100 表示上100个版本
```

git reset --hard HEAD^ //回退到上一个版本

git reset --hard [commit ID] //回退到指定的某一次提交后的版本

git reflog //查看使用的 Git 命令记录日志

git diff HEAD -- [file name] //查看工作区文件与版本库中最新版本的区别

git diff --staged //查看暂存区的不同

git reset HEAD [file name] //撤销添加到暂存区的文件修改

git checkout -- [file name] //撤销工作区文件的修改

git rm [file name] //从版本库中删除文件

在服务器上部署Git后，创建一个远程代码库，将已经创建的本地库关联该远程库，使用命令git remote add origin git@[server-name:path]/[repository-name.git]

关联后，使用命令git push -u origin master第一次推送master分支的所有内容

此后，每次本地提交后，只要有必要，就可以使用命令git push origin master推送最新修改

git clone [repository path] //拷贝远程库到本地

git branch //查看分支

git branch [branch name] //创建一个分支

git checkout [branch name] //切换到指定分支

git checkout -b [branch name] //创建一个新的分支，并切换到该分支

git merge [branch name] //合并指定的分支到当前的分支

git branch -d [branch name] //删除指定的分支

git log --graph //查看分支合并图

git merge --no-ff -m "[comment message]" [branch name] //禁用 Fast forward 模式，保留分支历史信息

git stash //保存当前的工作现场

git stash list //查看保存的工作现场

git stash apply [stash index] //恢复指定的工作现场

git stash drop [stash index] //删除指定的工作现场

git stash pop //恢复工作现场并删除恢复的工作现场记录

git branch -D [branch name] //强制删除一个分支

git remote -v //查看远程库信息

git push [remote library name] [local branch name] //将本地的分支推送到远程库的对应分支

git push origin master //推送本地的 master 分支到远程库的对应分支上

git push origin dev //推送 dev 分支到远程库

git checkout -b dev origin/dev 创建与远程库对应的本地 dev 库

git branch --set-upstream dev origin/dev //设置本地库的 dev 分支与远程库的 dev 分支的链接

git pull origin master //拉取远程库分支的内容

git tag [tag name] //创建标签

git log --pretty=oneline --abbrev-commit //查询提交动作

git tag [tag name] [commit id] //创建的标签指向给定的提交操作

git tag -a [tag name] -m "[comment message]" [commit id] //创建有注释的标签

git show [tag name] //查看标签的具体信息

git tag -d [tag name] //删除标签

git push origin [tag name] //推送指定的标签到远程库

git push origin --tags //推送所有本地标签到远程库

//删除远程库的标签，要先删除本地的标签
```
git tag -d [tag name]
git push origin :refs/tags/[tag name]
```

在 Git 工作区的根目录下创建文件 .gitignore 文件，用来指定忽略的文件，被忽略的文件无法添加到暂存区，可用 git add -f [file name] 强制添加，或者用命令 git check-ignore -v [file name] 查看 .gitignore 文件是否忽略了该文件

配置Git的时候，加上 --global 是针对当前用户起作用的，如果不加，那只针对当前的仓库起作用。
当前用户的Git配置文件放在用户主目录下的一个隐藏文件 .gitconfig 中
每个仓库的Git配置文件都放在 .git/config 文件中

```
git config --global user.name "Your Name"
git config --global user.email "email@example.com"
git config --global color.ui true //配置颜色
```

为命令设置别名

```
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.br branch
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
```



