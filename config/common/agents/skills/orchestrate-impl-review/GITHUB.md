# GitHub ticket 与 PR 流程

本文件仅在用户要求 GitHub ticket/PR 操作时使用。使用本会话已授权的范围；启用本流程不自动授权 push、merge 或关闭 ticket。设计与 worker 计划确认沿用 [SKILL.md](SKILL.md)。

## 建立 ticket 和实现分支

1. 从本地 remote 和 GitHub 核实目标 `OWNER/REPO`、现有 ticket/PR、base branch 与 baseline SHA；复用用户指定的对象。记录 URL，后续命令显式指定仓库。
2. 创建 ticket 时写明目标、验收标准、非目标、已确认约束和验证边界。待确认的设计/策略标记为待确认；不要写成用户已接受的要求。将正文保存临时文件，再用 `gh issue create --repo OWNER/REPO --title TITLE --body-file FILE` 发布。
3. 从确认的 baseline 创建实现分支。先检查现有工作区 git 状态 clean；记录分支名和起点 SHA。Git mutations 串行执行。

完成条件：ticket URL、分支和 baseline 可核实，spec 区分已确认与待确认内容。已有 ticket 时读取正文及相关评论，以最新明确要求为准。

## 以评论更新 ticket

需求细化、设计决定、验收补充和范围变化都发布为新评论，保留 ticket 原文。评论注明相对既有要求的变化、确认状态和新增验收；引用相关原文/评论，避免复制整份 spec。

```sh
gh issue comment "$issue" --repo "$repo" --body-file "$comment_file"
```

保存返回的原生评论 URL，并将相关最新评论交给 worker 和 reviewer。后续明确确认的要求优先；存在未解决冲突时澄清，不能把较新的讨论建议直接当作已确认要求。

完成条件：更新内容作为可引用的评论存在，原正文保持不变，当前 spec 的来源和确认状态明确。

## 创建和维护 PR

默认在第一个 worker 完成提交、主 agent 核实交接并执行 gates 后创建 draft PR，再发布该 worker 的阶段评论；随后继续其余实现和 review。正文关联 ticket。创建前核实 head/base 并完成已授权的 push；远端已有同分支 PR 时更新该 PR。

```sh
gh pr create --repo "$repo" --base "$base" --head "$branch" \
  --draft --title "$title" --body-file "$body_file"
```

后续更新正文用 `gh pr edit --body-file`；title/body 随最终实现范围调整，以代码实际行为为准。

每个 worker 完成后，主 agent 验证后补齐最终结果并发布一条阶段评论再进入下一阶段。评论应包括：

- 提交 SHA/链接和阶段 diff 区间。
- 行为变化及其对应要求。
- gates/验收结果、失败原因或剩余验证；区分真实实测、mock/注入及未测场景。
- 建议的下一步

```sh
gh pr comment "$pr" --repo "$repo" --body-file "$comment_file"
```

取得评论 URL 后，将 PR body 的相关实现/验证细节简化为到**最新阶段评论**的 GitHub 原生链接；正文保留简短行为描述、ticket 引用和当前状态。评论是详细记录的单一来源，避免在 body 重复维护。若本次完整范围只部分完成，应明确剩余范围。

完成条件：远端 head 与交付提交一致，最新阶段评论存在，PR body 指向它并如实反映完成状态。

## 发布每轮 review

两个轴结束且父 agent 核实 findings 后，发布每轮 PR 评论：

- 固定 baseline、当前 HEAD、完整 diff 区间，以及上一轮被审 HEAD 到当前 HEAD 的增量区间。
- 分列 Standards / Spec 结论、findings 和证据，不合并或跨轴重排。
- 父 agent 对有效/无效 findings 的判断与依据、已解决项目和后续处理。第二轮未通过时按主流程暂停。
- 验证依据和边界；CLI 失败后恢复报告时说明恢复来源，保持实际命令状态可追溯。

正文链接到最新 review 评论，标明 PASS/FAIL/进行中。新增提交后旧 review 只能作为历史结论，不能继续宣称它覆盖新的 HEAD。完成后报告 PR URL、最终 head、review 结论和未测限制；merge、关闭 ticket 等操作等待对应授权。

完成条件：每轮结论和准确区间可在 PR 中追溯，body 与最新阶段/review 状态一致。

## 发布可靠性

正文/评论使用临时 UTF-8 文件与 `--body-file`，保留真实换行并避免 shell 插值。发布后保存 URL；命令状态不确定时先查已有对象/评论，确认是否成功后再重试，避免重复发布。报告不包含凭据，命令证据引用可公开的摘要及日志位置。
