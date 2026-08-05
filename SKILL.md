---
name: dev-workflow
description: 执行从需求评审、任务拆分、实施计划、AI 编码、代码审查、测试门禁到发布和事故复盘的证据化开发工作流。当用户明确要求 DoR/DoD 检查、L0-L3 分级、任务拆分、实施计划、正式代码或 PR 审查、测试/迁移/安全门禁、发布评审、事故复盘、阶段文档或工作流成熟度评估时使用。适用于个人开发者、小团队和 AI 辅助开发项目；不要因普通编码问答、简单修改或一般调试自动触发。
---

# Development Workflow

## 目标与边界

建立需求可追溯、任务可验收、代码可检查、发布可恢复、运行可监控、问题可复盘的开发闭环。

使用本 Skill 定义“如何执行开发流程”。始终以项目 `AGENTS.md`、PRD、业务规则、API 契约和数据库设计作为项目事实来源；不得用通用流程替代业务规则。

## 执行顺序

1. 查找并阅读项目根目录及上级目录中的 `AGENTS.md`。
2. 阅读用户指定的 Issue、PRD、业务规则、状态机、字段字典、API 和数据库设计。
3. 先识别当前开发阶段并选择阶段路由；不要预先加载其他阶段资源。
4. 仅在需求分级、规划、开发、DoD 或发布阶段需要风险深度时判断 L0-L3。
5. 检查当前阶段相关的代码、测试、迁移和 CI；纯需求任务没有仓库时，明确说明未做代码验证。
6. 将无法确认的内容标记为“待确认假设”，不得自行创造业务规则。
7. 执行对应检查或脚本，区分“已验证事实”“缺失证据”和“建议”。
8. 给出门禁结论、证据、风险和下一步动作；需要持久化时遵循 `references/document-output.md`。

## 阶段路由

| 用户意图 | 必读资源 | 按需使用的交付物或脚本 |
|---|---|---|
| 评审需求、判断能否开发 | `references/dor-checklist.md` | `templates/issue-template.md` |
| 判断需求复杂度 | `references/requirement-levels.md` | `templates/issue-template.md` |
| 拆分研发任务 | `references/task-decomposition.md` | `templates/task-template.md` |
| 准备编码、制定计划 | `templates/implementation-plan.md` | `references/testing-strategy.md` |
| 开发功能 | `references/ai-development-loop.md`、`references/testing-strategy.md` | `scripts/collect-quality-results.sh` |
| 审查代码或 PR | `references/code-review-checklist.md` | `templates/pr-template.md` |
| 判断是否完成 | `references/dod-checklist.md`、`references/testing-strategy.md` | `scripts/collect-quality-results.sh` |
| 数据库变更 | `references/database-migration.md` | `scripts/check-migrations.sh` |
| 安全评审 | `references/security-checklist.md` | `templates/pr-template.md` |
| 准备上线 | `references/release-checklist.md` | `templates/release-template.md`、`scripts/collect-quality-results.sh`、`scripts/check-migrations.sh` |
| 生产事故 | `references/incident-management.md` | `templates/incident-review.md` |
| 工作流评估 | `references/maturity-model.md` | `templates/workflow-review.md`、`scripts/check-project.sh` |
| 初始化项目协作规范或 CI | 当前项目技术栈资料 | `examples/AGENTS.example.md`、`examples/github-actions.example.yml` |

只读取当前阶段及其直接依赖的文件。多阶段请求按实际执行顺序逐阶段加载；需要保存文档时再读取 `references/document-output.md`。

## 按风险裁剪流程

需要判断风险深度时读取 `references/requirement-levels.md`，按其中的分级和自动升级条件执行：

- L0/L1 只做与当前改动直接相关的检查，使用精简输出。
- L2 完成当前阶段要求的正式计划、测试和证据，不提前执行尚未进入的发布门禁。
- L3 在当前阶段增加架构、迁移、恢复、监控、安全和人工验收要求。

## 评审发现分级

| 等级 | 定义 | 处理要求 |
|---|---|---|
| P0 | 已有证据表明将导致或正在导致数据丢失、严重安全事件或核心业务不可用 | 立即阻断 |
| P1 | 核心业务错误、严重兼容问题、关键测试缺失，或高风险场景缺少必须确认的规则/证据 | 默认阻断；仅能由明确责任人接受风险 |
| P2 | 可维护性、边界场景、一般性能或设计问题 | 建议本次修复或登记债务 |
| P3 | 文案、格式和轻量优化建议 | 可后续处理 |

缺少信息本身通常归为 P1 或 P2，不得仅因“可能造成严重后果”就判为 P0。只有存在直接证据证明 P0 后果已经发生或按当前方案必然发生时，才使用 P0。

## 全局门禁

- 验收标准不可测试，或核心状态、权限、数据范围和失败策略无法确定时，不进入正式开发。
- 不修改无关代码，不通过删除测试或降低标准解决失败；业务规则变化必须补测试。
- 必需 CI 未通过、存在未接受的 P1 或未审查 `git diff` 时，不允许合并。
- 数据库变更必须新增迁移，不得修改已执行迁移。
- 高风险发布缺少迁移验证、恢复方案、核心监控或发布后验证时，不允许发布。

当前阶段的详细门禁以阶段路由中的检查清单为唯一详细来源。

## 脚本使用

先解析本 `SKILL.md` 所在目录为 `<skill-dir>`，再运行脚本。不要假定当前工作目录就是 Skill 目录。

### 项目基础检查

```bash
<skill-dir>/scripts/check-project.sh <project-root>
```

- 默认要求 `AGENTS.md`、`.gitignore`、测试和任一常见 CI 配置。
- `AGENTS.md` 会从项目根目录向上查找；其他必需文件只检查项目根目录。
- 用 `REQUIRED_FILES='AGENTS.md:.gitignore:README.md'` 自定义必需文件。
- 用 `REQUIRE_TESTS=0` 或 `REQUIRE_CI=0` 关闭不适用的门禁。
- 用 `CHECK_PROJECT_DOCS=1` 启用 README 和 CHANGELOG 提示。
- CI 配置必须包含常见质量命令信号；特殊项目用 `CI_QUALITY_REGEX` 覆盖匹配正则。
- 结果只证明文件结构存在，不证明测试或 CI 已成功执行。

### 迁移结构检查

```bash
<skill-dir>/scripts/check-migrations.sh <migration-dir>
```

- 默认要求目录非空、文件非空、文件名以唯一数字前缀及 `_`/`-` 开头。
- 用 `MIGRATION_NAME_REGEX` 覆盖项目命名正则；正则的第一个捕获组必须是数字前缀。

### 质量结果收集

```bash
LINT_CMD='pnpm lint' \
TYPECHECK_CMD='pnpm typecheck' \
TEST_CMD='pnpm test' \
BUILD_CMD='pnpm build' \
REQUIRED_QUALITY_CHECKS='lint,typecheck,test,build' \
<skill-dir>/scripts/collect-quality-results.sh <project-root>
```

- 可配置 `LINT_CMD`、`TYPECHECK_CMD`、`TEST_CMD`、`BUILD_CMD`、`MIGRATION_CMD` 和 `SECURITY_CMD`。
- `TEST_CMD` 应聚合当前任务要求的单元、集成、契约或 E2E 测试，不得用单一低覆盖命令替代完整测试策略。
- `REQUIRED_QUALITY_CHECKS` 仅接受 `lint,typecheck,test,build,migration,security`；未知名称或配置不可用返回 `2`。
- 退出码 `0` 表示通过，`1` 表示检查失败或缺少必需检查，`2` 表示参数或配置错误。

脚本结果只是证据，不替代业务验收、代码审查或发布决策。

## 输出与持久化

- 纯评审、解释或报告默认只在对话输出；L0/L1 也默认使用对话摘要。
- 用户、项目规则或 L2/L3 完整开发流程要求保存阶段文档时，读取并遵循 `references/document-output.md`；只保存实际执行阶段并原位更新已有文档。
- 简单请求输出“结论、证据与风险、下一步”；正式评审或存在阻断项时补充当前阶段与等级、P0/P1、P2/P3 和交付物。
- 省略空章节；完成后列出实际新增或更新的文档路径，并说明未执行或未保存的阶段。

## 使用原则

1. 优先做最小必要检查，不为低风险变更制造过重流程。
2. 所有结论附带证据；未运行的检查必须说明原因。
3. 不重复询问项目资料中已有的信息。
4. 明确区分事实、待确认假设和改进建议。
5. 将反复出现的问题沉淀到规则、模板、脚本或 CI。
