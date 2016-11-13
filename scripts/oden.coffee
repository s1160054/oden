# Description
#  レビュー依頼Bot
#
# Dependencies:
#   "request": "2.78.0"
#   "cron": "1.1.0"
#
# Configuration:
#   CHANNEL - チャネル名
#   SELECT_NUM - レビューに必要な人数
#   FETCH_CRON - レビュー依頼可能なユーザーを更新する間隔をCronで指定
#   REJECT_CRON - レビュー依頼不能なユーザーのリストをリセットする間隔をCronで指定
#   RESET_CRON - レビュー依頼可能なユーザーをリセットする間隔をCronで指定
#   SUPER_USER
#
# Commands:
#    pr - レビュワーを選ぶ
#    users - レビュー依頼が可能なユーザーを表示(最近オンライン＆rejectsに含まれていないユーザー)
#    user+(.*) - レビュー依頼可能なユーザーに追加する(FETCH_CRONごとにリセット)
#    user-(.*) - レビュワーに選ばないようにする(REJECT_CRONごとにリセット)
#    rejects - レビュー不可リストを表示する(REJECT_CRONごとにリセット)
#    config - botの設定を表示する
#    helps - このヘルプを表示する
#
# Author:
#  s1160054
#

request = require('request')
cronJob = require('cron').CronJob

select_num    = process.env.SELECT_NUM  || 2
channel_name  = process.env.CHANNEL     || "random"
fetch_cron    = process.env.FETCH_CRON  || "*/1  *    * * *"
reset_cron    = process.env.RESET_CRON  || "0    */3  * * *"
reject_cron   = process.env.REJECT_CRON || "0    */24 * * *"
super_user    = process.env.SUPER_USER  || 'admin'
token = process.env.HUBOT_SLACK_TOKEN

module.exports = (robot) ->
  robot.logger.info config()
  fetch_online_users(robot)

  # 設定を表示する
  robot.hear /config/, (msg) =>
    msg.send config().join('\n')

  # ヘルプを表示する
  robot.hear /helps/, (msg) =>
    msg.send help().join('\n')

  # レビュワーを選ぶ
  robot.hear 'pr', (msg) =>
    online_users = get(robot, 'online_users')
    my_name = msg.message.user.name
    for name in [super_user, my_name]
      reject_idx = online_users.indexOf(name)
      online_users.splice(reject_idx, 1) if reject_idx != -1
    if online_users.length < select_num
      msg.send("アサインできるレビュワーが #{online_users.length} 名です\n")
      return
    online_users = random_fetch(online_users, select_num)
    msg.send("@#{online_users.join(', @')}")

  # ユーザーをレビュワーリストから除外する
  robot.hear /user-(.*)/, (msg) =>
    user = msg.match[1]
    user = msg.message.user.name if /me/.test(user)
    add(robot, 'reject_users', user)
    rm(robot, 'online_users', user)

  # ユーザーをレビュワーリストに追加する
  robot.hear /user\+(.*)/, (msg) =>
    user = msg.match[1]
    user = msg.message.user.name if /me/.test(user)
    add(robot, 'online_users', user)
    rm(robot, 'reject_users', user)

  # レビュワーリストを表示
  robot.hear /users/, (msg) =>
    online_users = get(robot, 'online_users')
    msg.send("レビュー可能: #{online_users.join(', ')}")

  # リジェクトユーザーを表示
  robot.hear /rejects/, (msg) =>
    reject_users = get(robot, 'reject_users')
    msg.send("レビュー不可: #{reject_users.join(', ')}")

  # reject_cronごとに、ユーザーをリセットする
  new cronJob(reject_cron, () ->
    robot.brain.set('reject_users', [])
    robot.logger.info "reset reject"
  ).start()

  # reset_cronごとに、ユーザーをリセットする
  new cronJob(reset_cron, () ->
    robot.brain.set('online_users', [])
    robot.logger.info "reset"
  ).start()

  # fetch_cronごとに、ユーザーを追加する
  new cronJob(fetch_cron, () ->
    fetch_online_users(robot)
  ).start()

  # 生存確認
  robot.router.get '/', (req, res) ->
    res.send 'pong'

##################################################

# 設定を配列で返す
config = () ->
  ["レビュワ: `#{select_num}人`",
   "チャネル: `#{channel_name}`",
   "レビュワー Fetch: `#{fetch_cron}`",
   "レビュワー Reset: `#{reset_cron}`",
   "リジェクト Reset: `#{reset_cron}`",]

# ヘルプを配列で返す
help = () ->
  ["`pr` \n レビュワーを選ぶ",
   "`users` \n レビュー依頼が可能なユーザーを表示\n最近オンライン＆rejectsに含まれていないユーザーです",
   "`user+hoge,piyo,tama` \n hoge,piyo,tamaをレビュー依頼可能なユーザーに追加する",
   "`user-piyo,tama` \n piyo,tamaをレビュワーに選ばないようにする\n１日毎に自動リセットされます",
   "`rejects` \n レビュー不可リストを表示する",
   "`config` \n botの設定を表示する",
   "`helps` \n このヘルプを表示する"]

# リストのユーザーを更新する
fetch_online_users = (robot) ->
  online_users = get(robot, 'online_users')
  robot.logger.info "List: #{online_users.join(', ')}"
  channels_list = "https://slack.com/api/channels.list?token=#{token}&pretty=1"
  request.get channels_list, (error, response, body) =>
    data = JSON.parse(body)
    channel = null
    for channel in data.channels
      channel = channel if channel.name == channel_name
    user_ids = channel.members.sort -> Math.random()
    for user_id in user_ids
      check_online(robot, user_id)

# リストに追加する
check_online = (robot, user_id) ->
  do (user_id) ->
    users_getPresence = "https://slack.com/api/users.getPresence?token=#{token}&user=#{user_id}&pretty=1"
    request.get users_getPresence, (error, response, body) =>
      data = JSON.parse(body)
      if (data.presence == "active")
        users_info = "https://slack.com/api/users.info?token=#{token}&user=#{user_id}&pretty=1"
        request.get users_info, (error, response, body) =>
          data = JSON.parse(body)
          return if data.user.is_bot
          user_name = data.user.name
          online_users = get(robot, 'online_users')
          robot.logger.info "Add:  #{user_name}" if online_users.indexOf(user_name) == -1
          online_users.push(user_name)
          robot.brain.set('online_users', uniq(online_users))

get = (robot, key) ->
    return (robot.brain.get(key) || []).slice(0)

rm = (robot, key, value) ->
    values = value.split(/[　・\s,、@]+/)
    arr = get(robot, key)
    for value in values
      reject_idx = arr.indexOf(value)
      arr.splice(reject_idx, 1) if reject_idx != -1
    robot.brain.set(key, arr)
    return arr

add = (robot, key, value) ->
    values = value.split(/[　・\s,、@]+/)
    arr = get(robot, key)
    arr = arr.concat(values)
    arr = uniq(arr)
    robot.brain.set(key, arr)
    return arr

uniq = (ar) ->
  if ar.length == 0
    return []
  res = {}
  res[ar[key]] = ar[key] for key in [0..ar.length-1]
  value for key, value of res

random_fetch = (array, num) ->
  a = array
  t = []
  r = []
  l = a.length
  n = if num < l then num else l
  while n-- > 0
    i = Math.random() * l | 0
    r[n] = t[i] or a[i]
    --l
    t[i] = t[l] or a[l]
  r
