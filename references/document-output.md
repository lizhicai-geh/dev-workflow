# 阶段文档输出规范

## 保存策略

1. 优先遵循项目 `AGENTS.md` 和既有文档目录；没有项目规范时使用 `docs/workflow/<work-id>/`。
2. `work-id` 优先使用已有 Issue/TASK 编号；没有编号时使用 `YYYYMMDD-short-slug`，不得虚构工单号。
3. L0/L1 默认只输出对话摘要；用户要求保存或项目规则要求留档时再写文件。
4. L2/L3 的开发、变更或完整工作流逐阶段保存。纯评审、解释或报告任务只有在用户明确要求时才写入项目。
5. 只创建实际执行阶段的文档。不得生成空占位文件，也不得把“未验证”写成“通过”。

## 默认目录与文件

| 阶段 | 默认文件 | 使用条件 |
|---|---|---|
| 工作流索引 | `00-index.md` | 保存两个及以上阶段时创建 |
| 上下文收集 | `01-context.md` | 需要记录来源、范围和约束时 |
| DoR 评审 | `02-dor-review.md` | 执行需求就绪检查时 |
| 需求分级 | `03-requirement-level.md` | 执行 L0-L3 分级时 |
| 任务拆分 | `04-task-breakdown.md` | 输出可开发任务时 |
| 实施计划 | `05-implementation-plan.md` | 编码前制定计划时 |
| 开发结果 | `06-development-report.md` | 完成代码或配置修改时 |
| 测试结果 | `07-test-report.md` | 执行自动化或人工验证时 |
| 代码审查 | `08-code-review.md` | 审查 diff 或 PR 时 |
| DoD 检查 | `09-dod-review.md` | 判断任务是否完成时 |
| 发布评审 | `10-release-review.md` | 判断版本是否可发布时 |
| 事故复盘 | `11-incident-review.md` | 发生事故并执行复盘时 |
| 成熟度评估 | `90-workflow-assessment.md` | 评估项目工作流时 |

单步执行时只写对应文件；完整流程每完成一个阶段就更新 `00-index.md`，不要等到最后一次性补写。

## 通用元数据

每个保存的 Markdown 文档都以以下 YAML frontmatter 开头：

```yaml
---
work_id: TASK-123
stage: implementation
status: draft
requirement_level: L2
source_commit: abc1234
updated_at: 2026-08-04T15:30:00+08:00
---
```

- `status` 仅使用 `draft`、`blocked`、`passed`、`failed`、`completed` 或 `superseded`。
- 没有 Git 仓库或尚无提交时，将 `source_commit` 写为 `unavailable` 并说明原因。
- 未确认的需求等级写为 `pending`，不得自行猜测。
- 时间使用带时区的 ISO 8601 格式。

## 通用正文

除模板已经提供等价章节外，每个阶段文档至少包含：

```markdown
# 文档标题

## 结论

## 已验证证据

## 待确认假设

## 风险与问题

## 交付物

## 下一步动作
```

- 明确区分事实、缺失证据和建议。
- 使用仓库相对路径链接源文件；记录精确命令、退出码和关键结果。
- 不复制大段日志，只保留结论和定位失败所需的片段。
- 不写入密钥、令牌、个人信息、生产数据或未经脱敏的日志。
- P0/P1 未关闭时将状态设为 `blocked`，并写明责任人、关闭条件和验证方式；未知责任人写 `待指定`。

## 各阶段必填内容

| 阶段 | 必填内容 | 复用模板 |
|---|---|---|
| 上下文 | 用户目标、范围/非目标、`AGENTS.md`、业务资料、代码与 CI 来源、缺失资料 | 无 |
| DoR | 关键项证据、缺失规则、P0/P1、门禁结论 | `templates/issue-template.md` |
| 分级 | 命中条件、自动升级条件、最终等级、最低交付物 | `references/requirement-levels.md` |
| 任务拆分 | 任务 ID、目标、依赖、范围、验收、测试、风险、复杂度、可并行性 | `templates/task-template.md` |
| 实施计划 | 现有实现、预计文件、步骤、数据库/API/安全影响、测试与恢复 | `templates/implementation-plan.md` |
| 开发结果 | 修改文件、实现内容、关键决策、计划偏差、遗留项 | `references/ai-development-loop.md` |
| 测试结果 | 环境、命令、退出码、通过/失败/跳过、覆盖范围、失败定位 | `references/testing-strategy.md` |
| 代码审查 | 审查范围和 SHA、按 P0-P3 排列的发现、测试证据、剩余风险 | `references/code-review-checklist.md` |
| DoD | 每项通过/失败/不适用及证据、最终结论 | `references/dod-checklist.md` |
| 发布 | 版本、范围、CI/staging、迁移、策略、监控、恢复、Go/No-Go | `templates/release-template.md` |
| 事故 | 影响、时间线、根因、恢复、机制缺口、改进负责人和期限 | `templates/incident-review.md` |
| 成熟度 | 各能力证据和评分、当前等级、P0/P1、分阶段改进路线 | `templates/workflow-review.md` |

## 更新与交付规则

1. 原位更新同一阶段文件，保留用户已有内容；重大结论变化在文档中记录日期、原结论和变化原因。
2. 文档结论必须与当前代码和最新测试一致；代码变化后同步更新受影响的计划、测试、DoD 和发布文档。
3. `00-index.md` 记录各阶段文件、状态、最后更新时间、依赖和当前阻断项，并使用相对链接。
4. 阶段通过后再推进下一门禁；被阻断时先保存证据和关闭条件。
5. 最终对话列出所有新增或更新文件，并概述结论、阻断项和未执行阶段。
