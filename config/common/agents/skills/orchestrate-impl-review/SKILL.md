---
name: orchestrate-impl-review
description: Orchestrate an design-implementation-review workflow
disable-model-invocation: true
---

编排以下工作流：

## 主流程

1. 若需求有模糊不清之处，按照 skill `grilling` 向用户提问，直到其清晰明确（至少要明确目标、验收标准和非目标），直到达到shared understanding。
2. 若需要设计新模块或public interface，按照 skill `codebase-design` 进行设计，然后输出设计选项。若设计已经存在，或可以简单地确定，可以跳过这一步，此时输出可以跳过的理由。暂停，等待用户确认后，再进入下一步。
3. 进行以下implement-review-stage迭代（默认进行2轮，如果第二轮review还没有通过则报告review结果并暂停，等待用户确认后再继续）。
  1. 选择：将本轮实现/修复拆分为多个子任务并委派多个workers实施，或者仅由单个worker实施。输出原因以及计划（包括每个worker应该产生哪些提交），暂停并等待用户确认。然后可以按计划串行地启动worker(s)。
  如果项目规定了某些gate（例如format、lint或者test等等），令worker在报告完成之前要么通过它们，要么报告不通过的理由（如gate与目标冲突等）。
  2. 检查git状态clean，并执行gates，确认其通过。
  3. 按照 skill `code-review` 复用已有的reviewer sub-agents review变更。告诉reviewers gates已经被执行。
  当启动新的一组fresh reviewers而没有复用时，传递获取完整变更 `BASE...HEAD_SHA` 的命令；
  如果复用，为了避免重复获取上下文中已有的变更，传递获取增量变更 `PREVIOUS_REVIEWED_HEAD..HEAD_SHA` 的命令，但此时review的对象仍然是完整变更。
  4. 若review未通过，检查哪些review findings真正有效且需要修复。然后返回迭代的第一步，让worker修复；若review已通过，则退出本skill流程。

## 可选流程

仅在用户明确要求时阅读对应文档；两项可独立启用，沿用本会话已确认的选择：

- **codexctl**：用户要求用 codexctl 启动 workers 或 reviewers 时，阅读 [CODEXCTL.md](CODEXCTL.md)。
- **GitHub**：用户要求创建 ticket、以评论更新 ticket，或创建/更新 PR 时，阅读 [GITHUB.md](GITHUB.md)。仓库托管在 GitHub 本身不触发阅读。

