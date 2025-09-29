# my-dev-setup
一键配置wsl开发环境，安装 zsh、oh-my-zsh、htop、bat、jq、vim；设置 zsh 为默认 shell；保证多次运行安全（幂等），并保留回滚点。
## 研究工具引导脚本

### day1_bascis.sh
一个演示Bash脚本基础功能的示例脚本

```bash
#运行示例
./scripts/day1_basics.sh /etc/hosts 5
```

功能包括：
- 文件头部分行显示
- grep/awk/sed 文本处理演示
- 错误处理和输入验证
