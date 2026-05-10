# Git 提交规范

> 字趣阅读项目组 | 生效日期：2026-05-11

## Commit 格式

```
<type>: <简短描述>

[可选的详细说明]
```

## Type 分类

| Type | 用途 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat: 绘本04-08真实图片接入` |
| `fix` | Bug 修复 | `fix: 测评API路由冲突 500→405` |
| `docs` | 文档更新 | `docs: API契约文档更新至v1.3` |
| `refactor` | 代码重构 | `refactor: Model层统一_id转id输出` |
| `test` | 测试相关 | `test: 新增questionGenerator单元测试` |
| `chore` | 杂项/构建 | `chore: 更新.gitignore` |
| `style` | 代码格式 | `style: 统一缩进为2空格` |
| `perf` | 性能优化 | `perf: 绘本图片懒加载` |

## 硬性约束

| 规则 | 说明 |
|------|------|
| 单次提交 ≤ 20 文件 | 超过 20 个文件需拆分为多个逻辑 commit |
| ≥ 50 文件 → 必须拆分 | 禁止大提交（如 232 文件），必须拆为多个 commit |
| 一个 commit 一个逻辑 | 不混合无关改动 |
| 描述用中文 | 方便团队阅读理解 |

## 分支策略

```
main ← 功能分支（feature/xxx）
  ↑
  ├── feat/绘本插画接入
  ├── fix/测评路由冲突
  └── refactor/BLoC迁移
```

- `main`：稳定分支，通过 PR 合并
- `feat/*` / `fix/*` / `refactor/*`：功能分支，开发完成后发起 PR

## Code Review 要求

- 每个 PR 至少 1 人 review 后 approve
- `flutter analyze` / `npm run lint` 必须通过
- 关联的测试必须通过
- PR 描述必须包含：改动原因 + 影响范围 + 测试方式

## 回滚

如需回滚，使用 `git revert <commit-hash>`，不要使用 `git reset --hard`。
