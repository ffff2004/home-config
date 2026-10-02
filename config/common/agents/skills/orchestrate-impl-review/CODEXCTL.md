# 使用 codexctl 委派

本文件仅在用户要求以 codexctl 执行 workers 或 reviewers 时使用。设计确认、worker 计划确认、gates 和迭代结束条件沿用 [SKILL.md](SKILL.md)；这里只规定执行与交接方式。

## 启动 worker

主流程确认计划后，给 worker 一份可独立执行的 prompt，包含：

- 目标、权威 spec 来源、验收标准和非目标；指定仓库、分支及起始 SHA。
- 文件/模块所有权；说明它不独占 checkout，应适配他人改动、保留他人编辑。同仓库 Git refs/锁写入操作串行执行；多个实现 worker 按主流程串行启动。
- 要创建的提交、必须执行的 gates、适用的行为/设备验收，以及临时 fixture 的清理责任。
- 父 agent 与 worker 的发布分工；默认由父 agent 执行 push 和 GitHub 写入，worker 交付代码、提交和证据。
- 交接报告位置，要求记录 SHA、命令、exit code、日志/结果路径、验收结果、限制、假设和 pitfalls/friction。

通过参数列表或可靠引用传入 prompt，保留原始换行。默认启动形式为：

```sh
codexctl start --cwd "$repo" --sandbox danger-full-access -- "$prompt"
```

具体 codexctl 用法可参考 skill `codexctl-as-subagent` 及 codexctl reference.md 文档。

完成条件：worker 交付提交和报告；父 agent 读取最终 handoff，检查 clean 状态，核实验收证据并执行主流程 gates 后才进入 review。

## 启动与复用 reviewers

按照 `code-review` 分别启动 Standards 和 Spec 两个独立 reviewer，可并行执行。每个 prompt 包含该轴的完整规则、权威来源、已完成 gates 的结果及验证边界，并明确职责为只读审查 Standards/Spec 轴；为了减少摩擦，默认使用 `--approve-for-me`，但prompt要禁止修改代码、Git refs、外部应用或提交 GitHub approval。

- **Fresh**：传递固定 baseline 和被审 HEAD 的准确 SHA，以及 `git diff BASE...HEAD_SHA`、`git log BASE..HEAD_SHA --oneline`。要求独立获取完整变更。用户要求 fresh 时新建一组；之后可复用这组。
- **复用**：保持 baseline 固定，传递增量的 `git diff PREVIOUS_REVIEWED_HEAD..HEAD_SHA` ；说明 review 对象仍为完整 baseline 到当前 HEAD。按需检查相关未变调用路径，避免重复读取全部旧 diff。
- **结论**：分别交付 PASS/FAIL、未解决 findings 数、已解决旧 findings，以及精确文件/行证据；保留两轴独立报告。父 agent 核实 findings，再按主流程处理有效问题。

启动用 `codexctl start`，后续轮次用 `codexctl resume THREAD_ID -- "$prompt"`，携带本会话选定的执行参数。使用临时文件/脚本组装长 prompt，避免 shell 展开改变内容。

完成条件：两个 reviewer 都有对应轮次的终态和最终报告；异步命令仅启动或其中一轴完成均不足以宣布 review 通过。

## 恢复与交接

按需查看 `codexctl status --json THREAD_ID`。终态后从持久化 history 取最终报告：

```sh
codexctl history --json --turns -1 "$thread_id" \
  | jq -r '.turns[0].items | map(select(.type == "agentMessage")) | last | .text // empty'
```

核对消息属于预期轮次且是最终报告；中途进度消息不能作为结论。

连接中断、error 或 unsupported interaction 时，读取原 thread 的状态/history 与日志，解决阻塞后再 resume 同一 thread。保留失败记录，不通过另起 thread 掩盖失败。CLI 订阅失败而 thread 已完成时，可恢复其持久化最终报告，并明确记录恢复依据和命令失败。

结束本轮前保存下一步、所有 threadId/被审 SHA、未完成 job 路径和已发布记录。
