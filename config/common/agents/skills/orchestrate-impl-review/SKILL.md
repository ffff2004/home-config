---
name: orchestrate-impl-review
description: Orchestrate an design-implementation-review workflow
disable-model-invocation: true
---

作为指挥者和总设计师完成以下编排：

1. 若需求有模糊不清之处，按照 `grilling` 向用户提问，直到其清晰明确（要明确实现和不实现的范围，以免覆盖范围过大）
2. 若模块组织和public interface设计尚未完成，按照 `codebase-design` 启动sub-agents进行设计并输出方案选项，然后暂停。若设计已经存在，或可以简单地确定，可以跳过这一步，但仍然需要暂停并输出理由和设计，让用户确认
3. 用户确定设计之后，启动一个sub-agent（这里称为worker）来实现
4. 实现完成后，按照 `code-review` 进行review
    - 若审查未通过，进行以下迭代（修改和复审1轮，如果还没有通过则暂停并报告review结果）：
        1. stage当前变更
        2. 让worker sub-agent进行修改
        3. 让reviewer sub-agents进行复审，审查对象是unstaged diff
5. 审查通过后，你来进行项目要求的最终（提交前置/PR前置）检查，确保所有要求都已满足
6. 提交变更，并进行其他收尾工作。例如，如果任务与一个issue相关，就勾选checklist、并关闭issue
