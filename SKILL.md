---
name: dev-workflow
description: 执行从需求评审、任务拆分、实施计划、AI 编码、代码审查、测试门禁到发布和事故复盘的证据化开发工作流。当用户明确要求 DoR/DoD 检查、L0-L3 分级、任务拆分、实施计划、正式代码或 PR 审查、测试/迁移/安全门禁、发布评审、事故复盘、阶段文档或工作流成熟度评估时使用。适用于个人开发者、小团队和 AI 辅助开发项目；不要因普通编码问答、简单修改或一般调试自动触发。
---

# Development Workflow

## 执行

1. 先读取项目及上级目录的 `AGENTS.md`，再读取用户指定的需求、规则、契约和数据设计；项目事实优先于本 Skill。
2. 识别当前阶段，只加载下表对应资料。多阶段任务按实际顺序推进，不预读后续阶段。
3. 检查相关代码、测试、迁移和 CI；无仓库时明确未做代码验证。
4. 区分已验证事实、缺失证据、待确认假设和建议，不自行补造业务规则。
5. 给出结论、证据、风险与下一步；需要留档时再读取[文档输出规范](references/document-output.md)。

## 阶段路由

| 阶段 | 读取 | 按需使用 |
|---|---|---|
| DoR 与分级 | [DoR](references/dor-checklist.md)、[L0–L3](references/requirement-levels.md) | [Issue 模板](templates/issue-template.md) |
| 拆分与计划 | [任务拆分](references/task-decomposition.md)、[测试策略](references/testing-strategy.md) | [任务模板](templates/task-template.md)、[计划模板](templates/implementation-plan.md) |
| 开发与 DoD | [开发循环](references/ai-development-loop.md)、[测试策略](references/testing-strategy.md)、[DoD](references/dod-checklist.md) | `scripts/collect-quality-results.sh` |
| 代码、数据或安全审查 | [代码审查](references/code-review-checklist.md)、[数据库迁移](references/database-migration.md)、[安全](references/security-checklist.md) | [PR 模板](templates/pr-template.md)、`scripts/check-migrations.sh` |
| 发布 | [发布检查](references/release-checklist.md)、[数据库迁移](references/database-migration.md) | [发布模板](templates/release-template.md)、质量与迁移脚本 |
| 事故 | [事故管理](references/incident-management.md) | [复盘模板](templates/incident-review.md) |
| 成熟度或项目初始化 | [成熟度模型](references/maturity-model.md) | [评估模板](templates/workflow-review.md)、`scripts/check-project.sh`、[AGENTS 示例](examples/AGENTS.example.md)、[CI 示例](examples/github-actions.example.yml) |

## 风险与门禁

需要调整流程深度时按 [L0–L3](references/requirement-levels.md) 执行：L0/L1 只做直接检查；L2 要求正式计划、测试和证据；L3 增加架构、迁移、恢复、监控、安全和人工验收。

| 等级 | 含义 | 处理 |
|---|---|---|
| P0 | 已证实会造成数据丢失、严重安全事件或核心业务不可用 | 阻断 |
| P1 | 核心错误、严重兼容问题、关键测试或规则缺失 | 默认阻断，除非责任人明确接受风险 |
| P2 | 一般边界、性能、设计或维护问题 | 修复或登记债务 |
| P3 | 文案、格式或轻量优化 | 可后续处理 |

- 核心状态、权限、数据范围、失败策略或可测试验收标准不明确时，不进入开发。
- 不改无关代码，不以删除测试、降低标准或忽略 P1 换取通过。
- 必需 CI 未通过或 `git diff` 未审查时，不允许合并。
- 数据库变更只新增迁移；高风险发布必须具备迁移验证、恢复方案、监控和发布后验证。

## 脚本

先将本文件所在目录解析为 `<skill-dir>`，再运行相关脚本：

```bash
<skill-dir>/scripts/check-project.sh <project-root>
<skill-dir>/scripts/check-migrations.sh <migration-dir>

LINT_CMD='pnpm lint' TEST_CMD='pnpm test' \
REQUIRED_QUALITY_CHECKS='lint,test' \
<skill-dir>/scripts/collect-quality-results.sh <project-root>
```

质量脚本还支持 `TYPECHECK_CMD`、`BUILD_CMD`、`MIGRATION_CMD` 和 `SECURITY_CMD`。退出码 `0/1/2` 分别表示通过、检查失败、参数或配置错误。脚本只产生证据，不替代业务验收或发布决策。

## 输出

- 简单任务输出结论、证据/风险和下一步；正式评审再按 P0–P3 排列发现，省略空章节。
- 默认在对话中交付。仅在用户、项目规则或完整 L2/L3 流程要求时保存实际执行阶段，并列出更新路径与未执行检查。
