# Oden

レビュワーを選んでくれるSlack用のBot

# Features

 - Slack APIを使います
 - 特定チャネルのオンラインのユーザーを、ランダムに複数人選びます
 - レビュー対象者リストと、対象除外者リストをRedisで保持します
 - それぞれのリストはSlack上のメッセージで追加削除できます

# Configuration

 - CHANNEL - チャネル名
 - SELECT_NUM - レビューに必要な人数 : 2
 - FETCH_CRON - レビュー依頼可能なユーザーを更新する間隔をCronで指定 :  "*/1  *    * * *"
 - REJECT_CRON - レビュー依頼不能なユーザーのリストをリセットする間隔をCronで指定 "0    */24 * * *"
 - RESET_CRON - レビュー依頼可能なユーザーをリセットする間隔をCronで指定 : "0    */3  * * *"
 - SUPER_USER

# Commands

 - pr - レビュワーを選ぶ
 - users - レビュー依頼が可能なユーザーを表示(最近オンライン＆rejectsに含まれていないユーザー)
 - user+(.*) - レビュー依頼可能なユーザーに追加する(FETCH_CRONごとにリセット)
 - user-(.*) - レビュワーに選ばないようにする(REJECT_CRONごとにリセット)
 - rejects - レビュー不可リストを表示する(REJECT_CRONごとにリセット)
 - config - botの設定を表示する
 - help - このヘルプを表示する

### Running oden Locally

You can start oden locally by running:

    % bin/hubot --adapter slack

You'll see some start up output and a prompt:

    [Sat Feb 28 2015 12:38:27 GMT+0000 (GMT)] INFO Using default redis on localhost:6379 oden>
