# Oden

レビュワーを選んでくれるSlack用のBot

## Features

 - Slack APIを使います
 - 特定チャネルのオンラインのユーザーを、ランダムに複数人選びます
 - レビュー対象者リストと、対象除外者リストをRedisで保持します
 - それぞれのリストはSlack上のメッセージで追加削除できます

## Commands

| Cmd | Description| Detail |
|---|---| --- |
| pr | レビュワーを選ぶ | |
| users | レビュー依頼が可能なユーザーを表示 | 最近オンライン＆rejectsに含まれていないユーザー |
| user+(.*) | レビュー依頼可能なユーザーに追加する | FETCH_CRONごとにリセット<br>カンマや空白区切りで複数可 |
| user-(.*) | レビュワーに選ばないようにする | REJECT_CRONごとにリセット<br>カンマや空白区切りで複数可 |
| rejects | レビュー不可リストを表示する | REJECT_CRONごとにリセット |
| config | botの設定を表示する | |
| helps | ヘルプを表示する | |

## Configuration

|Config Variable| Default value | Description|
|---|---|---|
| CHANNEL | "random" | レビュワーのいるチャネル名 |
| SELECT_NUM | 2 | レビューに必要な人数 |
| FETCH_CRON | "*/1  *    * * *" => １分毎 |  レビュー依頼可能なユーザーを更新する間隔をCronで指定 |
| REJECT_CRON | "0    0 * * *" => 毎日０時 | レビュー依頼不能なユーザーをリセットする間隔をCronで指定 |
| RESET_CRON |  "0    */3  * * *" => ３時間毎 | レビュー依頼可能なユーザーをリセットする間隔をCronで指定 |
| SUPER_USER | | |

## Running oden Locally

You can start oden locally by running:

    % bin/hubot --adapter slack

You'll see some start up output and a prompt:

    [Sat Feb 28 2015 12:38:27 GMT+0000 (GMT)] INFO Using default redis on localhost:6379 oden>
