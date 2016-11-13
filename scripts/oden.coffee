# Description:
#   レビュー依頼用Bot oden

request = require('request')
cronJob = require('cron').CronJob

select_num   = process.env.SELECT_NUM || 1
channel_name = process.env.CHANNEL    || "random"
fetch_cron    = process.env.FETCH_CRON   || "*/10 * * * * *"
reset_cron    = process.env.RESET_CRON   || "*/20 * * * * *"
reject_cron   = process.env.REJECT_CRON  || "*/40 * * * * *"

token = process.env.HUBOT_SLACK_TOKEN

module.exports = (robot) ->
  robot.logger.info config()
  fetch_online_users(robot)

  # 設定を表示する
  robot.hear /config/, (msg) =>
    msg.send config().join('\n')

  # レビュー依頼する
  # 引数はPRのURL
  robot.hear /https:\/\/github.com\/.+\/.+\/pull\/\d+/, (msg) =>
    online_users = (robot.brain.get('online_users') || []).slice(0)
    my_name = msg.message.user.name
    reject_idx = online_users.indexOf(my_name)
    online_users.splice(reject_idx, 1)
    if online_users.length < select_num
      msg.send("アサインできるレビュワーが #{online_users.length} 名です\n")
      return
    random_fetch(online_users, select_num)
    msg.send("@#{online_users.join(', @')} \n こちらのレビューお願いします #{msg.match} \n from #{my_name}")

  # ユーザーを表示
  robot.hear /users/, (msg) =>
    online_users = robot.brain.get('online_users') || []
    msg.send("オンライン: #{online_users.join(', ')}")

  # ユーザーをリストから除外する
  robot.hear /users-(.*)/, (msg) =>
    user = msg.match[1]

    online_users = (robot.brain.get('online_users') || []).slice(0)
    reject_idx = online_users.indexOf(user)
    online_users.splice(reject_idx, 1)
    robot.brain.set('online_users', online_users)

    reject_users = (robot.brain.get('reject_users') || []).slice(0)
    reject_users.push(user)
    reject_users = uniq(reject_users)
    robot.brain.set('reject_users', reject_users)
    msg.send("リジェクトユーザー: #{reject_users.join(', ')}")

  robot.hear /reject_users/, (msg) =>
    reject_users = (robot.brain.get('reject_users') || []).slice(0)
    msg.send("リジェクトユーザー: #{reject_users.join(', ')}")

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
  ["レビュワ: #{select_num}人",
   "チャネル: #{channel_name}",
   "フェッチ間隔: #{fetch_cron}",
   "リセット間隔: #{reset_cron}"]

# リストのユーザーを更新する
fetch_online_users = (robot) ->
  online_users = robot.brain.get('online_users') || []
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
          online_users = robot.brain.get('online_users') || []
          robot.logger.info "Add:  #{user_name}" if online_users.indexOf(user_name) == -1
          online_users.push(user_name)
          robot.brain.set('online_users', uniq(online_users))

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
