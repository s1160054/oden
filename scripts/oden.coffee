# Description:
#   レビュー依頼用Bot oden

request = require('request')
cronJob = require('cron').CronJob

select_num    = process.env.SELECT_NUM  || 2
channel_name  = process.env.CHANNEL     || "random"
fetch_cron    = process.env.FETCH_CRON  || "*/1  *    * * *"
reset_cron    = process.env.RESET_CRON  || "0    */3  * * *"
reject_cron   = process.env.REJECT_CRON || "0    */24 * * *"
super_user    = process.env.SUPER_USER  || 'onodera'
token = process.env.HUBOT_SLACK_TOKEN

module.exports = (robot) ->
  robot.logger.info config()
  fetch_online_users(robot)

  # 設定を表示する
  robot.hear /config/, (msg) =>
    msg.send config().join('\n')

  # レビュー依頼する
  robot.hear /https:\/\/github.com\/.+\/.+\/pull\/\d+/, (msg) =>
    online_users = get(robot, 'online_users')
    my_name = msg.message.user.name
    for name in [my_name, super_user]
      reject_idx = online_users.indexOf(name)
      online_users.splice(reject_idx, 1)
    if online_users.length < select_num
      msg.send("アサインできるレビュワーが #{online_users.length} 名です\n")
      return
    online_users = random_fetch(online_users, select_num)
    msg.send("@#{online_users.join(', @')} \n こちらのレビューお願いします \n #{msg.match} \n from #{my_name}")

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
    msg.send("オンライン: #{online_users.join(', ')}")

  # リジェクトユーザーを表示
  robot.hear /rejects/, (msg) =>
    reject_users = get(robot, 'reject_users')
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
   "オンラインユーザー Add:   #{fetch_cron}",
   "オンラインユーザー Reset: #{reset_cron}",
   "除外ユーザー       Reset: #{reset_cron}",]

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
    values = value.split(/[　・\s,]+/)
    arr = get(robot, key)
    for value in values
      reject_idx = arr.indexOf(value)
      arr.splice(reject_idx, 1) if reject_idx != -1
    robot.brain.set(key, arr)
    return arr

add = (robot, key, value) ->
    values = value.split(/[　・\s,、]+/)
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
