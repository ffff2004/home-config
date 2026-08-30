---
name: orchestrate-impl-review
description: Orchestrate an design-implementation-review workflow
disable-model-invocation: true
---

编排以下工作流：

1. 若需求有模糊不清之处，按照 `grilling` 向用户提问，直到其清晰明确（要明确实现和不实现的范围，以免覆盖范围过大）。在确认共识之后暂停等待用户确认
2. 若需要设计新模块和public interface，按照 `codebase-design` 启动sub-agents进行设计，然后输出设计选项。若设计已经存在，或可以简单地确定，可以跳过这一步，此时输出可以跳过的理由。暂停，等待用户确认设计后，再进入下一步
3. 进行以下implement-review-stage迭代（自主进行2轮，如果第二轮review还没有通过则报告review结果并暂停）。
如果 `codexctl-as-subagent` skill 存在，按照它的说明使用codexctl启动和管理worker和reviewer，
此时，告诉reviewers：它们自己就是某一轴的reviewer sub-agent，禁止启动reviewer sub-sub-agent。
注：对于每一轮实现/修复，启动新的worker；对于同一个任务的不同轮次，复用reviewers：
  1. 启动新的worker sub-agent来实现/修复，将变更保持unstaged。
  如果项目规定了某些gate（例如format、lint或者test等等），令worker在报告完成之前要么通过它们，
  要么报告不通过的理由（如gate与设计冲突，或满足其要求实际上会使代码质量下降）
  2. 按照 `code-review` 复用已有的reviewer sub-agents进行review，fixed-point为（修改之前的提交+staged diff），审查对象是unstaged diff
  注：如果启动了新的reviewers而没有复用，新的reviewers第一次review时将fixed-point重设为修改之前的提交
  3. 若review未通过，stage当前变更，然后返回迭代的第一步，让worker修复；若review已通过，则结束迭代并进入下一步
4. 最终审查通过后，你来执行一次项目要求的gate检查，确认其通过，或者报告不通过的理由并暂停
5. 提交变更
