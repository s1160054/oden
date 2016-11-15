# Oden

Bot for Slack to select reviewers.  
If you send the URL of PR to Bot, we will pick two reviewers and add them to Assignees of Github.

## Features

- Use the Slack API and Github API.
- Randomly select 2 online users for review channel.
- Correspondence table of Slack and Github ID is obtained by team.json of Git.
- Adjust so as not to consecutively make the same person reviewer.

## Running oden Locally

1.You can start oden locally by running:

    git clone https://github.com/s1160054/oden.git
    cd oden
    HUBOT_SLACK_TOKEN=xxxx GIT_API_TOKEN=yyyy SUPER_USER=<your_slack_name> bin/hubot --adapter slack
   

2.Edit this file to correspond to your team member:  
[team.json](https://github.com/s1160054/oden/blob/master/team.json)

```json
{
  "your_github_user_name": "your_slack_name",
  "sakuya": "izayoi.sakuya",
  "yukari": "yukari.yakumo",
  "meiling": "hong.meiling",
  "reimu": "reimu.hakurei"
}
```

Or if you want to make this JSON file private:

Please put the json file for the team in github and do like this.

    TEAM_JSON_URL=https://github.com/your_name/repo_name/blob/master/team.json

## Commands

| Cmd | Description|
|---|---| --- |
| URL of Pull-request | **I choose two reviewers and assign them.** |
| users | User's status display. |
| user+(.\*) | Add to reviewable users.　 <br>*user+me*<br> *user+sakuya, reimu* |
| user-(.\*) | Add users that can not be reviewed today. <br>*user-me*<br> *user-sakuya, reimu*  |
| user!-(.\*) | Keep users from reviewing at all times. <br>*user!-me*<br> *user!-sakuya, reimu* |
| user!+(.\*) | Always to revive the users who can not review. <br>*user!+me*<br> *user!+sakuya, reimu* |
| config | Display the bot setting. |

## Configuration

### Required

|Config Variable| |
|---|---|
| HUBOT_SLACK_TOKEN | https://my.slack.com/apps/A0F7YS25R-bots |
| GIT_API_TOKEN | https://github.com/settings/tokens |
| SUPER_USER | **your_slack_name** |

### Optional

|Config Variable| Default value |
|---|---|---|
| CHANNEL | random <br> Name of the channel where the reviewer is located |
| SELECT_NUM | Two persons(2) <br> Number of people required for review |
| FETCH_CRON | Every 10 minutes('\*/10 \* \* \* \*') <br> Interval to check user's online |
| SKIP_CRON | Daily 0:00('0 0 \* \* \*') <br> Interval to restore skipped users |
| CLEAR_CRON | Every hour('0 \*/1 \* \* \*') <br> The interval to remove offline users from users|
| ALERT_PATH | Daily 17:00('0 17 \* \* \*') <br> Periodic notification |
| JSON_PATH | ./db.json <br> Path of JSON file for persistence |
| TEAM_JSON_URL | ./team.json or https://github.com/your_name/repo_name/blob/master/team.json<br> ID linking Slack and GIt URL or Path |
| REQUEST_WORDING | Please review this review. |

## Install as a npm package

```sh
npm install oden-boy
```
> [oden-boy](https://www.npmjs.com/package/oden-boy)
