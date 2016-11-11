module.exports = (robot) ->
  robot.hear /[https:\/\/github.com\/.+\/.+\/pull\/\d+|.*]/, (msg) =>
    robot.logger.info msg
    select_user_num = 1
    include_self = true
    current_channel_name = "random"

    request = require('request')
    token = process.env.HUBOT_SLACK_TOKEN
    current_channel_name ||= msg.message.room
    channels_list = "https://slack.com/api/channels.list?token=#{token}&pretty=1"
    request.get channels_list, (error, response, body) =>
      return msg.send('SlackAPI： channels_listの取得に失敗しました') if error or response.statusCode != 200
      data = JSON.parse(body)
      console.log data
      channel = null
      for channel in data.channels
        channel = channel if channel.name == current_channel_name
      return msg.send('Hubot: チャネルが不明です') if channel == null
      user_ids = channel.members.sort -> Math.random()

      selected_users = []
      for user_id in user_ids
        do (user_id) ->
          users_getPresence = "https://slack.com/api/users.getPresence?token=#{token}&user=#{user_id}&pretty=1"
          request.get users_getPresence, (error, response, body) =>
            return msg.send('SlackAPI: users_getPresenceの取得に失敗しました') if error or response.statusCode != 200
            data = JSON.parse(body)
            console.log data
            if (data.presence == "active") && selected_users.length <= select_user_num
              users_info = "https://slack.com/api/users.info?token=#{token}&user=#{user_id}&pretty=1"
              request.get users_info, (error, response, body) =>
                return msg.send('SlackAPI: users_infoの取得に失敗しました') if error or response.statusCode != 200
                data = JSON.parse(body)
                console.log data
                if data.user.name != msg.message.user.name || include_self
                  selected_users.push(data.user.name)
                  msg.send("@#{selected_users.join(', @')} \n レビュー依頼 #{msg.match}") if selected_users.length == select_user_num