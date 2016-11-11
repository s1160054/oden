request = require('request')
module.exports = (robot) ->
  select_user_num = 1
  current_channel_name = "random"

  # レビュー依頼する
  # 引数はPRのURL
  robot.hear /https:\/\/github.com\/.+\/.+\/pull\/\d+/, (msg) =>
    online_users = (robot.brain.get('online_users') || []).slice(0)
    my_name = msg.message.user.name
    reject_idx = online_users.indexOf(my_name)
    online_users.splice(reject_idx, 1)
    if online_users.length < select_user_num
      msg.send("アサインできるオンラインレビュワーが #{select_user_num} 以下です\n`reload_online_users`でオンラインユーザーを更新します")
      return
    random_fetch(online_users, select_user_num)
    msg.send("@#{online_users.join(', @')} \n こちらのレビューお願いします #{msg.match} \n from #{my_name}")

  # DBのオンラインのユーザーを更新する
  robot.hear /online_users/, (msg) =>
    token = process.env.HUBOT_SLACK_TOKEN
    current_channel_name ||= msg.message.room
    channels_list = "https://slack.com/api/channels.list?token=#{token}&pretty=1"
    request.get channels_list, (error, response, body) =>
      return msg.send('SlackAPI： channels_listの取得に失敗しました') if error or response.statusCode != 200
      data = JSON.parse(body)
      channel = null
      for channel in data.channels
        channel = channel if channel.name == current_channel_name
      return msg.send('Hubot: チャネルが不明です') if channel == null
      user_ids = channel.members.sort -> Math.random()

      for user_id in user_ids
        do (user_id) ->
          users_getPresence = "https://slack.com/api/users.getPresence?token=#{token}&user=#{user_id}&pretty=1"
          request.get users_getPresence, (error, response, body) =>
            return msg.send('SlackAPI: users_getPresenceの取得に失敗しました') if error or response.statusCode != 200
            data = JSON.parse(body)
            if (data.presence == "active")
              users_info = "https://slack.com/api/users.info?token=#{token}&user=#{user_id}&pretty=1"
              request.get users_info, (error, response, body) =>
                return msg.send('SlackAPI: users_infoの取得に失敗しました') if error or response.statusCode != 200
                data = JSON.parse(body)
                user_name = data.user.name
                msg.send("オンライン: #{user_name}")
                online_users = robot.brain.get('online_users') || []
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