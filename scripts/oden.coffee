request = require('request')
cronJob = require('cron').CronJob

module.exports = (robot) ->
  select_num   = process.env.SELECT_NUM || 1
  channel_name = process.env.CHANNEL_NAME || "random"
  reset_sec    = process.env.RESET_SEC || 60
  fetch_sec    = process.env.FETCH_SEC || 10

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

  # オンラインのユーザーを表示
  robot.hear /online_users/, (msg) =>
    online_users = robot.brain.get('online_users') || []
    msg.send("オンライン: #{online_users.join(', ')}")

  # ６０秒ごとに、オンラインユーザーをリセットする
  new cronJob("*/#{reset_sec} * * * * *", () ->
    robot.brain.set('online_users', [])
    robot.logger.info "reset"
  ).start()

  # １０秒ごとに、オンラインユーザーを追加する
  new cronJob("*/#{fetch_sec} * * * * *", () ->
    token = process.env.HUBOT_SLACK_TOKEN
    channels_list = "https://slack.com/api/channels.list?token=#{token}&pretty=1"
    request.get channels_list, (error, response, body) =>
      data = JSON.parse(body)
      channel = null
      for channel in data.channels
        channel = channel if channel.name == channel_name
      user_ids = channel.members.sort -> Math.random()

      for user_id in user_ids
        do (user_id) ->
          users_getPresence = "https://slack.com/api/users.getPresence?token=#{token}&user=#{user_id}&pretty=1"
          request.get users_getPresence, (error, response, body) =>
            data = JSON.parse(body)
            if (data.presence == "active")
              users_info = "https://slack.com/api/users.info?token=#{token}&user=#{user_id}&pretty=1"
              request.get users_info, (error, response, body) =>
                data = JSON.parse(body)
                user_name = data.user.name
                robot.logger.info "オンライン: #{user_name}"
                online_users = robot.brain.get('online_users') || []
                online_users.push(user_name)
                robot.brain.set('online_users', uniq(online_users))
  ).start()

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