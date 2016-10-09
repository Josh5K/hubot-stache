request = require 'request'
fs = require 'fs'
temp = require 'temp'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0" #ignore cert errors

class Barber
  constructor: () ->

  moustachify: (fileName, cb) ->
    moustachify_options =
      resolveWithFullResponse: true
      url: "https://funnyface.neufeldtech.com/upload"
      formData:
        file: fs.createReadStream(fileName)
    ext = "." + fileName.split('.').pop()
    tempName = temp.path({suffix: ext})
    r = request.post(moustachify_options)
    r.on('error', (err) ->
      return cb "There was an error with the moustachification: #{err}")
    r.on('response', (response) ->
      if response.statusCode != 200
        return cb "There was an error with the moustachification: #{JSON.stringify(response.body)}"
      r.pipe(stream = fs.createWriteStream(tempName))
      stream.on 'finish', ->
        cb null, tempName)

  downloadSlackFile: (url, cb) ->
    options =
      url: url
      headers:
        Authorization: "Bearer #{process.env.HUBOT_SLACK_TOKEN}"
    ext = "." + url.split('.').pop()
    tempName = temp.path({suffix: ext})
    r = request.get(options)
    r.on('error', (err) ->
      return cb "There was an error getting the image attachment from slack :sob: #{err}")
    r.on('response', (response) ->
      if response.statusCode != 200
        return cb "There was an error getting the image attachment from slack :sob: #{response.body}"
      r.pipe(stream = fs.createWriteStream(tempName))
      stream.on 'finish', ->
        cb null, tempName)

module.exports = Barber
