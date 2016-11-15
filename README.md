# Oden

レビュワーを選ぶSlack用のBotおでん

## Features

 - Slack APIを使います
 - レビューチャネルのオンラインのユーザーを、ランダムに２人選びます
 - 連続して同じ人にレビュー依頼しないように調整してます
 - 次のデータをRedis & JSONで保持します
   1. User
     - オンラインユーザーリスト
   2. Skip
     - その日はレビューをスキップする人リスト
   3. Never
     - これから先レビューしない人リスト

## Commands

| Cmd | Description| Detail |
|---|---| --- |
| pr | レビュワーを選ぶ | |
| users | ユーザーのステータス表示 |このチャネルで１時間以内オンラインかつ、<br>１０分以内にレビュー依頼していない |
| user+(.*) | レビュー可能なユーザーに追加　|[user+me] or [user+yamada, hanako] |
| user-(.*) | 本日レビューできないユーザー追加 |[user-me] or [user-yamada, hanako]  |
| user!-(.*) | ユーザーを常にレビューできないようにする |[user!-me] or [user!-yamada, hanako] |
| user!+(.*) | 常にレビューできないユーザーを復活 |[user!+me] or [user!+yamada, hanako] |
| config | botの設定を表示する | |

## Configuration

|Config Variable| Default value | Description|
|---|---|---|
| CHANNEL | "random" | レビュワーのいるチャネル名 |
| SELECT_NUM | 2 | レビューに必要な人数 |
| FETCH_CRON | １０分毎 |  ユーザーのオンラインをチェックする間隔 |
| SKIP_CRON | 毎日０時 | スキップされたユーザーを復活させる間隔 |
| CLEAR_CRON | １時間毎 | オフラインユーザーをユーザーから外す間隔 |
| JSON_PATH | ./db.json | 永続化用JSONファイルのパス |
## Running oden Locally

You can start oden locally by running:

    % bin/hubot --adapter slack

You'll see some start up output and a prompt:

    [Sat Feb 28 2015 12:38:27 GMT+0000 (GMT)] INFO Using default redis on localhost:6379 oden>
