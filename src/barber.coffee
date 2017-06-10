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
defaultStaches = require('./public/config/stache/default.json')
defaultFaces = require('./public/config/face/default.json')

class Barber
  constructor: (@robot) ->
    robot = @robot
    firstBrainLoad = true
    robot.brain.on 'loaded', ->
      if firstBrainLoad
        firstBrainLoad = false
        robot.brain.set "faces", defaultFaces # load default faces into brain
        staches = robot.brain.get "staches"
        if !staches
          robot.logger.debug "Setting default staches in brain: #{JSON.stringify(defaultStaches)}"
          robot.brain.set "staches", defaultStaches
        else
          robot.logger.debug "Found staches in brain: #{JSON.stringify(staches)}"
        
  moustachify: (fileName, featureType, cb) ->
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
          
          eyeLeft = _.findWhere(landmarks, 'Type': 'eyeLeft')
          x_eyeLeft = eyeLeft.X * width
          y_eyeLeft = eyeLeft.Y * height
          
          eyeRight = _.findWhere(landmarks, 'Type': 'eyeRight')
          x_eyeRight = eyeRight.X * width
          y_eyeRight = eyeRight.Y * height
          
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
         
          boundingBox = face.BoundingBox
          faceWidth = boundingBox.Width * width
          faceHeight = boundingBox.Height * height
          faceLeft = boundingBox.Left * width
          faceTop = boundingBox.Top * height
         
          switch featureType
            when 'glasses'
              glassesStaches = _.filter staches, (s) ->
                s.featureType == "glasses"
              stacheFile = stachesDir + glassesStaches[Math.floor(Math.random() * glassesStaches.length)]['fileName']
              stacheWidth = faceWidth * 0.9
              stache_x_offset = (faceWidth - stacheWidth) * 2.75
              x_geometry = x_eyeLeft - stache_x_offset
              stache_y_offset = (y_eyeLeft - y_nose) / 1.75
              y_geometry = y_eyeLeft + stache_y_offset
            when 'hat'
              hatStaches = _.filter staches, (s) ->
                s.featureType == "hat"
              stacheFile = stachesDir + hatStaches[Math.floor(Math.random() * hatStaches.length)]['fileName']
              stacheWidth = faceWidth
              stacheHeight = faceHeight * 0.75
              stache_x_offset = (faceWidth - stacheWidth) / 2
              x_geometry = faceLeft - stache_x_offset
              y_geometry = faceTop - (stacheHeight * 0.85)
            else 
              # default is stache
              stacheStaches = _.filter staches, (s) ->
                s.featureType == "stache"
              stacheFile = stachesDir + stacheStaches[Math.floor(Math.random() * stacheStaches.length)]['fileName']
              stacheWidth = mouthWidth * 1.7
              stache_x_offset = (mouthWidth - stacheWidth) / 2
              x_geometry = x_mouthLeft + stache_x_offset
              stache_y_offset = (y_nose - y_mouthLeft) / 2
              y_geometry = y_mouthLeft + stache_y_offset
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
