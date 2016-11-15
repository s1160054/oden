# Oden

Bot for Slack to select reviewers.  
If you send the URL of PR to Bot, we will pick two reviewers and add them to Assignees of Github.

```sh
npm install oden-boy
```
> [oden-boy](https://www.npmjs.com/package/oden-boy)

## Running oden Locally

You can start oden locally by running:

    % bin/hubot --adapter slack HUBOT_SLACK_TOKEN=xxxx GIT_API_TOKEN=yyyy

## Features

- Use the Slack API and Github API.
- Randomly select 2 online users for review channel.
- Correspondence table of Slack and Github ID is obtained by team.json of Git.
- Adjust so as not to consecutively make the same person reviewer.

## Commands

| Cmd | Description| Detail |
|---|---| --- |
| Pull request URL | I choose two reviewers and assign them. | |
| users | User's status display. | I have not requested a review online within this channel for less than 10 minutes. |
| user+(.*) | Add to reviewable users.　| [user+me] or [user+yamada, hanako] |
| user-(.*) | Add users that can not be reviewed today. | [user-me] or [user-yamada, hanako]  |
| user!-(.*) | Keep users from reviewing at all times. | [user!-me] or [user!-yamada, hanako] |
| user!+(.*) | Always to revive the users who can not review. | [user!+me] or [user!+yamada, hanako] |
| config | Display the bot setting. | |

## Configuration

|Config Variable| Default value and Description|
|---|---|---|
| CHANNEL | *random* <br> Name of the channel where the reviewer is located |
| SELECT_NUM | *Two persons* <br> Number of people required for review |
| FETCH_CRON | *Every 10 minutes* <br> Interval to check user's online |
| SKIP_CRON | *Daily 0:00* <br> Interval to restore skipped users |
| CLEAR_CRON | *Every hour* <br> The interval to remove offline users from users|
| ALERT_PATH | *Every 1 day* <br> Periodic notification |
| JSON_PATH | *./db.json* <br> Path of JSON file for persistence |
| TEAM_JSON_URL | *./team.json*<br>or<br>*https://github.com/xxx/yyy/zzz/master/team.json*<br> ID linking Slack and GIt URL or Path |
| REQUEST_WORDING | *Please review this review.* | |
| HUBOT_SLACK_TOKEN | | |
| GIT_API_TOKEN | | |
