#Git学习总结
Git 是一种免费且开源的分布式版本控制系统，其可以高效且快速得管理很小或很大的工程。Git 简单易学，占用空间小但性能极好。他拥有远远超过其他诸如 Subversion 、CVS 、Perforce 、ClearCase 等 SCM 工具的特性。这些特性有简易的本地分支、方便的管理策略和多工作流等。

> SCM（Software Configuration Management，软件配置管理）是一种标识、组织和控制修改的技术软件。配置管理是指通过执行版本控制、变更控制的规程，以及使用合适的配置管理软件，来保证所有配置项的完整性和可跟踪性。

## Git 命令
git init
git  add <file>
git commit -m "<comment message>"
git status 
git diff <file>
git log
git log --pretty=oneline
HEAD 表示当前版本
HEAD^ 表示上一个版本
HEAD^^ 表示上上个版本
HEAD~100 表示上100个版本
git reset --hard HEAD^
git reset --hard <commit ID>
git reflog //查看使用的git命令记录日志
git diff HEAD -- <file name> //查看工作区文件与版本库中最新版本的区别
git reset HEAD <file name> //撤销添加到暂存区的文件修改
git checkout -- <file name> //撤销工作区文件的修改
git rm <file name> //从版本库中删除文件
在服务器上部署Git后，创建一个远程代码库，将已经创建的本地库关联该远程库，使用命令git remote add origin git@<server-name:path>/<repository-name.git>

关联后，使用命令git push -u origin master第一次推送master分支的所有内容

此后，每次本地提交后，只要有必要，就可以使用命令git push origin master推送最新修改

git clone <repository path> //拷贝远程库到本地

git branch //查看分支
git branch <branch name> //创建一个分支
git checkout <branch name> //切换到指定分支
git checkout -b <branch name> //创建一个新的分支，并切换到该分支
git merge <branch name> //合并指定的分支到当前的分支
git branch -d <branch name> //删除指定的分支
git log --graph //查看分支合并图
git merge --no-ff -m "<comment message>" <branch name> //禁用 Fast forward 模式，保留分支历史信息
git stash //保存当前的工作现场
git stash list //查看保存的工作现场