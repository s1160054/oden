module.exports = (robot) ->
  path = Path.resolve __dirname, 'scripts'
  Fs.exists path, (exists) ->
    if exists
      robot.loadFile path, file for file in Fs.readdirSync(path)