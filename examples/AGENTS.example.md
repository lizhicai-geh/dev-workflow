# 项目 AI 开发规范

## 项目事实

- 前端：`apps/web`
- 后端：`apps/api`
- 业务规则：`docs/business-rules`
- 数据库迁移：`migrations`
- 技术栈：React、TypeScript、MySQL 8（按项目修改）

## 质量命令

```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

## 规则

1. 以业务规则、字段字典和 API 契约为准，不自行推断缺失规则。
2. 只修改任务相关文件；数据库变化新增迁移。
3. 不删除或弱化测试规避失败。
4. 完成后汇报修改、测试、风险和未验证项。
