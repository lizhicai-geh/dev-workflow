---
name: dev-workflow
description: 执行从需求评审、任务拆分、实施计划、AI 编码、独立 AI 审查、自动测试门禁到发布和事故复盘的证据化自主开发工作流。当用户明确要求 DoR/DoD 检查、L0-L3 分级、任务拆分、实施计划、正式代码或 PR 审查、测试/迁移/安全门禁、发布评审、事故复盘、阶段文档或工作流成熟度评估时使用。适用于个人开发者、小团队和 AI 自主开发项目；不要因普通编码问答、简单修改或一般调试自动触发。
---

# Development Workflow

## 执行

1. 先读取项目及上级目录的 `AGENTS.md` 和 `.ai/workflow-policy.yml`，再读取用户指定的需求、规则、契约和数据设计；项目事实优先于本 Skill。
2. 默认采用 `autonomous_ai`：AI 持续执行下一项安全且可授权的工作，直到完成或遇到不可绕过的外部授权边界，不把开发步骤转交给用户。
3. 识别当前阶段，只加载下表对应资料。多阶段任务按实际顺序推进，不预读后续阶段。
4. 检查相关代码、测试、迁移和 CI；无仓库时明确未做代码验证。
5. 区分已验证事实、缺失证据、待验证假设和建议，不自行补造业务规则。
6. 每个阶段转换都记录输入、执行动作、结果和证据；实现与审查使用相互独立的 AI 验证轮次。
7. 给出结论、证据、风险与下一步；需要留档时再读取[文档输出规范](references/document-output.md)。

## 外部授权边界

只有以下情况可以暂停并请求用户授权：缺少仓库和现有证据无法确定的业务决策、缺少外部凭据或权限、即将执行不可逆生产操作。授权请求必须包含最小必要范围、风险、预期结果和验证方式；获得授权后继续由 AI 执行。

## 阶段路由

| 阶段 | 读取 | 按需使用 |
|---|---|---|
| DoR | [DoR](references/dor-checklist.md) | [Issue 模板](assets/templates/issue-template.md) |
| 需求分级 | [L0–L3](references/requirement-levels.md) | [Issue 模板](assets/templates/issue-template.md) |
| 任务拆分 | [任务拆分](references/task-decomposition.md) | [任务模板](assets/templates/task-template.md) |
| 实施计划 | [计划模板](assets/templates/implementation-plan.md) | [测试策略](references/testing-strategy.md) |
| 开发 | [开发循环](references/ai-development-loop.md)、[测试策略](references/testing-strategy.md) | `scripts/collect-quality-results.sh` |
| 代码或 PR 审查 | [代码审查](references/code-review-checklist.md) | [PR 模板](assets/templates/pr-template.md) |
| DoD | [DoD](references/dod-checklist.md)、[测试策略](references/testing-strategy.md) | `scripts/collect-quality-results.sh` |
| 数据库变更 | [数据库迁移](references/database-migration.md) | `scripts/check-migrations.sh` |
| 安全评审 | [安全](references/security-checklist.md) | [PR 模板](assets/templates/pr-template.md) |
| 发布 | [发布检查](references/release-checklist.md) | [发布模板](assets/templates/release-template.md)、质量脚本；涉及迁移时再读数据库规范 |
| 事故 | [事故管理](references/incident-management.md) | [复盘模板](assets/templates/incident-review.md) |
| 成熟度评估 | [成熟度模型](references/maturity-model.md) | [评估模板](assets/templates/workflow-review.md)、`scripts/check-project.sh` |
| 项目协作规范或 CI 初始化 | 当前项目技术栈资料 | [AGENTS 模板](assets/project-setup/AGENTS.md)、[CI 模板](assets/project-setup/quality.yml) |

## 风险与门禁

需要调整流程深度时按 [L0–L3](references/requirement-levels.md) 执行：L0/L1 只做直接检查；L2 要求正式计划、测试和证据；L3 增加架构、迁移、恢复、监控、安全和独立 AI 验收。

| 等级 | 含义 | 处理 |
|---|---|---|
| P0 | 已证实会造成数据丢失、严重安全事件或核心业务不可用 | 阻断 |
| P1 | 核心错误、严重兼容问题、关键测试或规则缺失 | 默认阻断；仅外部授权可接受明确范围内的残余风险 |
| P2 | 一般边界、性能、设计或维护问题 | 修复或登记债务 |
| P3 | 文案、格式或轻量优化 | 可后续处理 |

- 核心状态、权限、数据范围、失败策略或可测试验收标准不明确时，先由 AI 检索仓库证据；仍无法确定则进入外部授权边界，不进入开发。
- 不改无关代码，不以删除测试、降低标准或忽略 P1 换取通过。
- 必需 CI 未通过或 `git diff` 未审查时，不允许合并。
- 数据库变更只新增迁移；高风险发布必须具备迁移验证、恢复方案、监控和发布后验证。
- 不接受空白勾选项、口头结论或个人角色作为门禁证据；无法自动验证的检查记为阻断项。

## 脚本

先将本文件所在目录解析为 `<skill-dir>`，再运行相关脚本：

```bash
<skill-dir>/scripts/check-project.sh <project-root>
<skill-dir>/scripts/check-ai-autonomy.sh <project-root>
<skill-dir>/scripts/check-migrations.sh <migration-dir>

LINT_CMD='pnpm lint' TEST_CMD='pnpm test' \
REQUIRED_QUALITY_CHECKS='lint,test' \
<skill-dir>/scripts/collect-quality-results.sh <project-root>
```

质量脚本还支持 `TYPECHECK_CMD`、`BUILD_CMD`、`MIGRATION_CMD` 和 `SECURITY_CMD`。退出码 `0/1/2` 分别表示通过、检查失败、参数或配置错误。脚本只产生证据，不替代业务验收或发布决策。

- 项目检查默认要求 `AGENTS.md`、`.ai/workflow-policy.yml`、`.gitignore`、测试和含质量命令的 CI；用 `REQUIRED_FILES`、`REQUIRE_TESTS`、`REQUIRE_CI`、`CHECK_PROJECT_DOCS` 和 `CI_QUALITY_REGEX` 调整。
- 自主性审计要求机器策略、AI 规则和 CI 门禁存在，并阻断非 AI 执行角色、空白勾选项及辅助开发定位。
- 迁移检查默认要求非空文件及唯一数字前缀；用 `MIGRATION_NAME_REGEX` 覆盖命名规则，其首个捕获组必须为数字。
- `REQUIRED_QUALITY_CHECKS` 仅接受 `lint,typecheck,test,build,migration,security`；`TEST_CMD` 应覆盖当前任务要求的测试层级。

## 输出

- 简单任务输出结论、证据/风险和下一步；正式评审再按 P0–P3 排列发现，省略空章节。
- 默认在对话中交付。仅在用户、项目规则或完整 L2/L3 流程要求时保存实际执行阶段，并列出更新路径与未执行检查。
