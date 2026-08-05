# AI 开发执行循环

## 开始前

1. 阅读 `AGENTS.md`。
2. 阅读当前任务和关联文档。
3. 检查现有实现和测试。
4. 明确禁止修改的范围。
5. 输出实施计划和预计修改文件。

## 开发中

- 小步修改，每步保持可验证；
- 优先复用现有组件和模式；
- 新增规则同步补测试；
- 数据库变化新增迁移；
- 不做无关格式化或重构；
- 不使用临时硬编码掩盖问题；
- 不删除测试解决失败。

## 完成前

依项目实际命令执行：

- lint；
- typecheck；
- unit test；
- integration test；
- contract test；
- build；
- migration check；
- security scan。

然后检查：

```bash
git status
git diff --stat
git diff
```

## 最终输出

- 修改文件；
- 已实现内容；
- 测试命令和结果；
- 未执行检查及原因；
- 已知风险；
- 遗留事项；
- 是否满足验收标准。
