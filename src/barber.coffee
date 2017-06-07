request = require 'request'
fs = require 'fs'
temp = require 'temp'
AWS = require('aws-sdk')
fs = require('fs')
exec = require('child_process').exec
gm = require('gm')
imageMagick = gm.subClass({ imageMagick: true });
async = require('async')
_ = require('underscore')

# DEBUGGING
fakepayload = require('/home/jordan/dev/nubot/payload.json')
# END DEBUGGING

rekognition = new (AWS.Rekognition)(
  region: 'us-west-2'
  accessKeyId: process.env.HUBOT_AWS_REKOGNITION_ACCESS_KEY_ID
  secretAccessKey: process.env.HUBOT_AWS_REKOGNITION_SECRET_ACCESS_KEY)

# staches = [ 'original_stache.png', 'mustache_03.png', 'painters_brush.png', 'petite_handlebar.png' ]

# console.log(robot.brain.get "staches")
stachesDir = __dirname + '/public/templates/'
# staches = fs.readdirSync(stachesDir)
staches = undefined
defaultStaches = require('./public/defaultStaches.json')

class Barber
  constructor: (@robot) ->
    robot = @robot
    firstBrainLoad = true
    robot.brain.on 'loaded', ->
      if firstBrainLoad
        firstBrainLoad = false
        staches = robot.brain.get "staches"
        if !staches
          robot.logger.debug "Setting default staches in brain: #{JSON.stringify(defaultStaches)}"
          robot.brain.set "staches", defaultStaches
        else
          robot.logger.debug "Found staches in brain: #{JSON.stringify(staches)}"
        
  moustachify: (fileName, cb) ->
    robot = @robot
    inputFile = fileName
    outputFile = temp.path({suffix: 'png'})
    faceBytes = fs.readFileSync(inputFile)
    params = Image: Bytes: faceBytes
    width = undefined
    height = undefined
    async.waterfall [
      (callback) ->
        imageMagick(inputFile).size (err, value) ->
          if err
            return callback(err)
          width = value.width
          height = value.height
          callback()
        return
      # (callback) ->
      #   rekognition.detectFaces params, callback
      #   return
      (callback) ->
        return callback(null, fakepayload)
      (payload, callback) ->
        robot.logger.debug "HERE COMES THE FULL PAYLOAD!"
        robot.logger.debug JSON.stringify(payload)
        command = []
        command.push 'convert', inputFile
        _.each payload.FaceDetails, (face) ->
          # console.log "HERE COMES A FACE!"
          # console.log JSON.stringify(face)
          landmarks = face.Landmarks
          nose = _.findWhere(landmarks, 'Type': 'nose')
          x_nose = nose.X * width
          y_nose = nose.Y * height
          mouthLeft = _.findWhere(landmarks, 'Type': 'mouthLeft')
          x_mouthLeft = mouthLeft.X * width
          y_mouthLeft = mouthLeft.Y * height
          mouthRight = _.findWhere(landmarks, 'Type': 'mouthRight')
          x_mouthRight = mouthRight.X * width
          y_mouthRight = mouthRight.Y * height
          mouthWidth = x_mouthRight - x_mouthLeft
          stacheWidth = mouthWidth * 1.6
          stache_x_offset = (mouthWidth - stacheWidth) / 2
          x_geometry = x_mouthLeft + stache_x_offset
          stache_y_offset = (y_nose - y_mouthLeft) / 2
          y_geometry = y_mouthLeft + stache_y_offset
          stacheFile = stachesDir + staches[Math.floor(Math.random() * staches.length)]['fileName']
          command.push stacheFile, '-geometry', Math.floor(stacheWidth) + 'x+' + Math.floor(x_geometry) + '+' + Math.floor(y_geometry), '-composite'
          return
        command.push outputFile
        exec command.join(' '), callback
        return
    ], (error, success) ->
      if error
        return cb "There was an error: #{error}"
      cb null, outputFile

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
