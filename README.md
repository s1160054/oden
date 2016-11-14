# Oden

レビュワーを選ぶSlack用のBotおでん

## Features

 - Slack APIを使います
 - レビューチャネルのオンラインのユーザーを、ランダムに２人選びます
 - データをRedis & JSONで保持します
   1. User
     - オンラインユーザーリスト
   2. Skip
     - その日はレビューをスキップする人リスト
   3. Never
     - これから先レビューしない人リスト
     
 **これらのデータはSlack上のメッセージで操作できます。詳細は後述します**

## Commands

| Cmd | Description| Detail |
|---|---| --- |
| pr | レビュワーを選ぶ | |
| users | ユーザーを表示 | `１時間以内にオンライン` ＆ `skips`でも`nevers`でもないユーザー |
| user+(.*) | ユーザーを追加する | カンマや空白区切りで複数可 |
| user-(.*) | ユーザーをスキップする | その日だけレビューをスキップする<br>カンマや空白区切りで複数可 |
| skips | スキップされたユーザーを表示 |  |
| nevers | 削除されたユーザーを表示 |  |
| never+(.*) | ユーザーを削除 | 永遠にレビューをスキップする<br>カンマや空白区切りで複数可 |
| never-(.*) | ユーザーを復活 | レビューを再開する<br>カンマや空白区切りで複数可 |
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
