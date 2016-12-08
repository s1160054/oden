# Description
# Bot for Slack to select reviewers.
# If you send the URL of PR to Bot, we will pick two reviewers and add them to Assignees of Github.
#
# Dependencies:
#   "request": "2.78.0"
#   "cron": "1.1.0"
#
# Configuration:
#   REVIEW_CHANNEL - Name of the channel where the reviewer is located
#   NUMBER_OF_REVIEWERES - Number of people required for review
#   FETCH_INTERVAL - Interval to check user's online
#   SKIP_INTERVAL  - Interval to restore skipped users
#   CLEAR_INTERVAL - The interval to remove offline users from users
#   ALERT_INTERVAL - Periodic notification
#   DB_PATH  - Path of JSON file for persistence
#   TEAM_JSON_URL - ID linking Slack and GIt URL or Path
#   NEVER_USERS - Keep users from reviewing at all times
#   REQUEST_WORDING - Please review this pull request
#
# Configuration(PRIVATE):
#   NAME_OF_ADMINS_SLACK - Administrator name of this bot
#   NAME_OF_ADMINS_GIT - User name to use with Git API
#   HUBOT_SLACK_TOKEN
#   GIT_API_TOKEN
#
# Commands:
#    Pull request URL - I choose two reviewers and assign them.
#    users      - User's status display.
#    user+(.*)  - Add to reviewable users.
#    user-(.*)  - Add users that can not be reviewed today.
#    user!-(.*) - Keep users from reviewing at all times.
#    user!+(.*) - Always to revive the users who can not review.
#    config - Display the bot setting.
#
# Author:
#  s1160054
#

request = require('request')
cronJob = require('cron').CronJob
fs      = require('fs')
child_process = require('child_process')
env = process.env
public_config =
  number_of_reviewers: env.NUMBER_OF_REVIEWERES || 2
  review_channel:      env.REVIEW_CHANNEL       || 'random'
  fetch_interval:      env.FETCH_INTERVAL       || '0 */10 * * * *'
  clear_interval:      env.CLEAR_INTERVAL       || '0 59 * * * *'
  skip_interval:       env.SKIP_INTERVAL        || '0 0 0 * * *'
  alert_interval:      env.ALERT_INTERVAL       || '0 14 * * 1-5'
  db_path:             env.DB_PATH              || './db.json'
  request_wording:     env.REQUEST_WORDING      || 'Please review this pull request.'
  team_json_url:       env.TEAM_JSON_URL        || './team.json'
  never_users:         env.NEVER_USERS          || ''
private_config =
  name_of_admins_slack: env.NAME_OF_ADMINS_SLACK || 'your_slack_name'
  name_of_admins_git:   env.NAME_OF_ADMINS_GIT   || 'your_git_name'
  slack_token:          env.HUBOT_SLACK_TOKEN
  git_api_token:        env.GIT_API_TOKEN

module.exports = (robot) ->
  robot.brain.setAutoSave false

  load = ->
    robot.logger.info "load"
    data = JSON.parse fs.readFileSync public_config.db_path, encoding: 'utf-8'
    robot.brain.mergeData data
    robot.brain.setAutoSave true

  create_user_map = ->
    robot.logger.info "create_user_map"
    if fs.existsSync public_config.team_json_url
      user_map = JSON.parse fs.readFileSync public_config.team_json_url, encoding: 'utf-8'
      for k, v of user_map
        add(robot, '_'+v.replace(/[@\<\>\_]/g, ""), k.replace(/[@\<\>]/g, ""))
    else
      t = public_config.team_json_url.match(/(https:\/\/github.com)\/(.*)\/(.*)\/(.*)\/(.*)/)
      api_url = "https://api.github.com/repos/#{t[2]}/contents/#{t[5]}"
      team_json_api = "curl -u #{private_config.name_of_admins_git}:#{private_config.git_api_token} #{api_url}"
      child_process.exec team_json_api, (error, stdout, stderr) ->
        download_url = JSON.parse(stdout)['download_url']
        download_api = "curl -u #{private_config.name_of_admins_git}:#{private_config.git_api_token} #{download_url}"
        child_process.exec download_api, (error, stdout, stderr) ->
          user_map = JSON.parse(stdout)
          for k, v of user_map
            add(robot, '_'+v.replace(/[@\<\>\_]/g, ""), k.replace(/[@\<\>]/g, ""))

  save = (data) ->
    fs.writeFileSync public_config.db_path, JSON.stringify data

  robot.brain.on 'loaded', save
  load()
  create_user_map()

  robot.logger.info config()
  fetch_users(robot)
  rm(robot, 'users', public_config.never_users)
  add(robot, 'never_users', public_config.never_users)

  # Display the bot setting.
  robot.respond /config/, (msg) =>
    msg.send "\n#{config()}"

  # I choose two reviewers and assign them.
  robot.respond /https:\/\/github.com\/(.*)\/(.*)\/pull\/(.*)/, (msg) =>
    users = get(robot, 'users')
    never_users = get(robot, 'never_users')
    skip_users = get(robot, 'skip_users')
    my_name = msg.message.user.name
    for name in ([private_config.name_of_admins_slack, my_name].concat(never_users).concat(skip_users))
      skip_idx = users.indexOf(name)
      users.splice(skip_idx, 1) if skip_idx != -1
    if users.length < public_config.number_of_reviewers
      msg.send("There are #{users.length} reviewers that can be assigned.\n")
      fetch_users(robot)
      return
    selected_users = random_fetch(users, public_config.number_of_reviewers)
    for name in selected_users
      rm(robot, 'users', name)
    assign_users_with_url(msg.match[0], selected_users, msg, robot)

  # Add users that can not be reviewed today.
  robot.respond /user-(.*)/, (msg) =>
    user = msg.match[1]
    user = msg.message.user.name if /me/.test(user)
    add(robot, 'skip_users', user)
    rm(robot, 'users', user)

  # Add to reviewable users.　
  robot.respond /user\+(.*)/, (msg) =>
    user = msg.match[1]
    user = msg.message.user.name if /me/.test(user)
    add(robot, 'users', user)
    rm(robot, 'skip_users', user)

  # User's status display.
  robot.respond /users/, (msg) =>
    msg.send(users_msg(robot).join('\n'))

  # Always to revive the users who can not review.
  robot.respond /user!\+(.*)/, (msg) =>
    user = msg.match[1]
    user = msg.message.user.name if /me/.test(user)
    add(robot, 'users', user)
    rm(robot, 'never_users', user)

  # Keep users from reviewing at all times.
  robot.respond /user!\-(.*)/, (msg) =>
    user = msg.match[1]
    user = msg.message.user.name if /me/.test(user)
    add(robot, 'never_users', user)
    rm(robot, 'users', user)

  # Interval to restore skipped users
  new cronJob(public_config.skip_interval, () ->
    robot.brain.set('skip_users', [])
    robot.logger.info "skip"
  ).start()

  # The interval to remove offline users from users
  new cronJob(public_config.clear_interval, () ->
    robot.brain.set('users', [])
    robot.logger.info "clear"
    fetch_users(robot)
  ).start()

  # Interval to check user's online
  new cronJob(public_config.fetch_interval, () ->
    fetch_users(robot)
    robot.logger.info "fetch"
  ).start()

  # Periodic notification
  new cronJob(public_config.alert_interval, () ->
    robot.logger.info "Periodic notification"
    envelope = room: public_config.review_channel
    robot.send envelope, users_msg(robot).join('\n')
  ).start()

  # Pong
  robot.router.get '/', (req, res) ->
    res.send 'pong'

##################################################

# Return the setting as an array.
config = () ->
  configs = []
  for k, v of public_config
    configs.push("#{k} : #{v}")
  "```#{configs.join('\n')}```"

# Display the status of the user.
users_msg = (robot) ->
  users_list = get(robot, 'users')
  skip_users = get(robot, 'skip_users')
  never_users = get(robot, 'never_users')
  ["```[Pull request URL] => I choose two reviewers and assign them.\nThe review request has been made not to be continuous to the same person for 10 minutes.\nhttps://github.com/s1160054/oden/blob/master/README.md```",
   "*Reviewable users* => `user+me`\n#{users_list.join(', ')}",
   "*Users who can not be reviewed today* => `user-me`\n#{skip_users.join(', ')}",
   "*Users who can not always review* => `user!-me`\n#{never_users.join(', ')}"]

# Update users
fetch_users = (robot) ->
  users = get(robot, 'users')
  robot.logger.info "List: #{users.join(', ')}"
  groups_list = "https://slack.com/api/groups.list?token=#{private_config.slack_token}&pretty=1"
  request.get groups_list, (error, response, body) =>
    data = JSON.parse(body)
    target_channel = null
    for group in data.groups
      target_channel = group if group.name == public_config.review_channel
    if target_channel
      user_ids = target_channel.members.sort -> Math.random()
      for user_id in user_ids
        check_online(robot, user_id)
    else
      channels_list = "https://slack.com/api/channels.list?token=#{private_config.slack_token}&pretty=1"
      request.get channels_list, (error, response, body) =>
        data = JSON.parse(body)
        for channel in data.channels
          target_channel = channel if channel.name == public_config.review_channel
        user_ids = target_channel.members.sort -> Math.random()
        for user_id in user_ids
            check_online(robot, user_id)

# Add users
check_online = (robot, user_id) ->
  do (user_id) ->
    users_getPresence = "https://slack.com/api/users.getPresence?token=#{private_config.slack_token}&user=#{user_id}&pretty=1"
    request.get users_getPresence, (error, response, body) =>
      data = JSON.parse(body)
      if (data.presence == "active")
        users_info = "https://slack.com/api/users.info?token=#{private_config.slack_token}&user=#{user_id}&pretty=1"
        request.get users_info, (error, response, body) =>
          data = JSON.parse(body)
          return if data.user.is_bot
          user_name = data.user.name
          never_users = get(robot, 'never_users')
          skip_users = get(robot, 'skip_users')
          return if (never_users + skip_users).indexOf(user_name) != -1
          users = get(robot, 'users')
          robot.logger.info "Add:  #{user_name}" if users.indexOf(user_name) == -1
          users.push(user_name)
          robot.brain.set('users', uniq(users))

assign_users_with_url = (url, assign_users, msg, robot) ->
    pull_req = url.match(/https:\/\/github.com\/(.*)\/(.*)\/pull\/(.*)/)[1..3]
    git_users = []
    invalid_users = []
    for assign_user in assign_users
      git_user = find_git_user(robot, assign_user)
      if git_user != null
        git_users.push(git_user)
      else
        invalid_users.push(assign_user)
    msg.send("There is no ID linking between Slack and Git. @#{invalid_users.join(' @')}") if invalid_users.length > 0
    post_users_json = "{\"assignees\": [\"#{git_users.join("\",\"")}\"]}"
    git_api_uri = "curl -v -H 'Accept: application/json' -d \'#{post_users_json}\' -u #{private_config.name_of_admins_git}:#{private_config.git_api_token
} https://api.github.com/repos/#{pull_req[0]}/#{pull_req[1]}/issues/#{pull_req[2]}/assignees"
    console.log git_api_uri
    child_process.exec git_api_uri, (error, stdout, stderr) ->
      res = JSON.parse(stdout)
      msg.send("@#{assign_users.join(' @')}　#{public_config.request_wording}\n*#{res.title}*\n#{url.match(/https:\/\/github.com\/(.*)\/(.*)\/pull\/(.*)/)[0]}\n")

find_git_user = (robot, user_name) ->
  return robot.brain.get("_#{user_name}")

get = (robot, key) ->
    return (robot.brain.get(key) || []).slice(0)

rm = (robot, key, value) ->
    values = value.split(/[　・\s,、@]+/)
    arr = get(robot, key)
    for value in values
      skip_idx = arr.indexOf(value)
      arr.splice(skip_idx, 1) if skip_idx != -1
    robot.brain.set(key, arr)
    console.log "#{key} #{robot.brain.get(key, arr)}"
    return arr

add = (robot, key, value) ->
    values = value.split(/[　・\s,、@]+/)
    arr = get(robot, key)
    arr = arr.concat(values)
    arr = uniq(arr)
    arr.splice arr.indexOf(''), 1 if arr.indexOf('') != -1
    robot.brain.set(key, arr)
    console.log "#{key} #{robot.brain.get(key, arr)}"
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
