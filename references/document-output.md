# 阶段文档输出

仅在用户、项目规则或完整 L2/L3 流程要求留档时使用。

## 保存

1. 优先遵循项目规范；否则写入 `docs/workflow/<work-id>/`。
2. `work-id` 使用真实任务编号；无编号时使用 `YYYYMMDD-short-slug`，不得虚构。
3. 只创建已执行阶段；同阶段原位更新，不生成空占位或重复版本。
4. 保存两个以上阶段时创建 `00-index.md`，记录链接、状态、时间、依赖和阻断项。

| 阶段 | 默认文件 |
|---|---|
| 上下文 / DoR / 分级 | `01-context.md` / `02-dor-review.md` / `03-requirement-level.md` |
| 拆分 / 计划 / 开发 | `04-task-breakdown.md` / `05-implementation-plan.md` / `06-development-report.md` |
| 测试 / 审查 / DoD | `07-test-report.md` / `08-code-review.md` / `09-dod-review.md` |
| 发布 / 事故 / 成熟度 | `10-release-review.md` / `11-incident-review.md` / `90-workflow-assessment.md` |

## 元数据

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

- `status` 使用 `draft|blocked|passed|failed|completed|superseded`。
- 无提交时 `source_commit: unavailable` 并说明原因；未确认等级写 `pending`。
- 时间使用带时区的 ISO 8601。

## 内容与证据

包含结论、已验证证据、待确认假设、风险、交付物和下一步；复用当前阶段模板，省略空章节。记录相对文件路径、精确命令、退出码和必要结果，不复制长日志或写入密钥、个人信息和生产数据。

| 阶段 | 必填证据 |
|---|---|
| 上下文 / DoR / 分级 | 目标、范围、资料来源与缺口；关键项证据、规则缺口和门禁；分级命中项、升级原因与最低交付物 |
| 拆分 / 计划 | 任务依赖、范围、验收、测试、风险和并行性；现有实现、预计文件、步骤、影响、测试与恢复 |
| 开发 / 测试 | 修改文件、实现、关键决策、计划偏差和遗留项；环境、命令、退出码、通过/失败/跳过、覆盖与失败定位 |
| 审查 / DoD | 审查范围与 SHA、P0–P3、测试证据和剩余风险；逐项状态、证据与最终结论 |
| 发布 | 版本、范围、CI/staging、迁移、策略、监控、恢复与 Go/No-Go |
| 事故 | 影响、时间线、根因、恢复、机制缺口及带负责人和期限的改进项 |
| 成熟度 | 各能力证据和评分、当前等级、P0/P1 与分阶段改进路线 |

P0/P1 未关闭时设为 `blocked`，记录责任人（未知则 `待指定`）、关闭条件和验证方式。重大结论变化需记录日期、原结论和原因。代码或测试变化后同步更新受影响文档；最终列出更新路径、结论、阻断项和未执行阶段。
