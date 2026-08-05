# Dev Workflow

面向 AI 辅助开发的证据化工作流 Skill，覆盖需求、计划、开发、审查、测试、发布与复盘；按阶段按需加载资料，并按 L0–L3 风险调整检查深度。

## 安装

```bash
npx skills add lizhicai-geh/dev-workflow     # 当前项目
npx skills add lizhicai-geh/dev-workflow -g  # Codex 全局
npx skills@latest add . -a codex             # 当前仓库
```

## 使用

显式指定 `$dev-workflow`，并提供当前阶段、目标和已有资料：

```text
使用 $dev-workflow 对需求做 DoR 检查并列出阻断项。
使用 $dev-workflow 拆分可独立验收的研发任务。
使用 $dev-workflow 审查当前分支并执行 DoD 检查。
使用 $dev-workflow 判断本次发布是否 Go-Live。
```

阶段路由、门禁和脚本用法见 [`SKILL.md`](SKILL.md)。

## 验证

```bash
bash tests/test-scripts.sh
```
