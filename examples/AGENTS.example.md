# 项目 AI 开发规范

## 项目结构

- 前端：`apps/web`
- 后端：`apps/api`
- 业务规则：`docs/business-rules`
- 数据库迁移：`migrations`

## 技术栈

- 前端：React + TypeScript + shadcn/ui
- 后端：按项目填写
- 数据库：MySQL 8

## 常用命令

```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

## 强制规则

1. 业务规则以 `docs/business-rules` 为准。
2. 状态和枚举以字段字典为准。
3. API契约以 OpenAPI 文件为准。
4. 不确定规则不得自行推断。
5. 只修改当前任务相关文件。
6. 数据库变更必须新增迁移。
7. 不得删除测试规避失败。
8. 完成后必须汇报修改、测试和风险。
