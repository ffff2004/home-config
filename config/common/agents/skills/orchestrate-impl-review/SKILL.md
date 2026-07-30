---
name: orchestrate-impl-review
description: Orchestrate an design-implementation-review workflow
disable-model-invocation: true
---

编排以下工作流：

1. 若需求有模糊不清之处，按照 `grilling` 向用户提问，直到其清晰明确（要明确实现和不实现的范围，以免覆盖范围过大）
2. 若模块组织和public interface设计尚未完成，按照 `codebase-design` 启动sub-agents进行设计，然后输出设计选项并暂停。若设计已经存在，或可以简单地确定，可以跳过这一步，但仍然需要暂停并输出理由和设计（如果只需在现有代码的基础上修改，也输出修改点），让用户确认
3. 用户确定设计之后，进行以下implement-review-stage迭代（自主进行2轮，如果第二轮review还没有通过则报告review结果并暂停）：
  1. 让sub-agent（这里称为worker）来实现。如果项目规定了某些gate（例如format、lint或者test等等），令worker在报告完成之前要么通过它们，要么报告不通过的理由（如gate与设计冲突，或满足其要求实际上会使代码质量下降）
  2. 按照 `code-review` 让reviewer sub-agents进行review，审查对象是unstaged diff
  3. 若review未通过，stage当前变更，然后返回迭代的第一步，让worker修复；若review已通过，则结束迭代并进入下一步
5. 最终审查通过后，你来执行一次项目要求的gate检查，确认其通过，或者报告不通过的理由并暂停
6. 提交变更，并进行其他收尾工作。例如，如果任务与一个issue相关，就勾选checklist、并关闭issue
