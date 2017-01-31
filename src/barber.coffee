request = require 'request'
fs = require 'fs'
temp = require 'temp'
AWS = require('aws-sdk')
uuid = require('node-uuid')
fs = require('fs')
exec = require('child_process').exec
gm = require('gm')
async = require('async')
_ = require('underscore')

rekognition = new (AWS.Rekognition)(
  region: 'us-west-2'
  accessKeyId: process.env.HUBOT_AWS_ACCESS_KEY_ID
  secretAccessKey: process.env.HUBOT_AWS_SECRET_ACCESS_KEY)

staches = [ 'stache.png', 'colonel_mustard.png', 'grand-handlebar.png', 'mustache_03.png', 'painters-brush.png', 'petite-handlebar.png' ]
stachesDir = __dirname + '/templates/'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0" #ignore cert errors

class Barber
  constructor: () ->
  moustachify: (fileName, cb) ->
    inputFile = fileName
    outputFile = temp.path({suffix: 'png'})
    faceBytes = fs.readFileSync(inputFile)
    params = Image: Bytes: faceBytes
    width = undefined
    height = undefined
    async.waterfall [
      (callback) ->
        gm(inputFile).size (err, value) ->
          if err
            return callback(err)
          width = value.width
          height = value.height
          callback()
        return
      (callback) ->
        rekognition.detectFaces params, callback
        return
      (payload, callback) ->
        command = []
        command.push 'convert', inputFile
        _.each payload.FaceDetails, (face) ->
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
          stacheFile = stachesDir + staches[Math.floor(Math.random() * 6)]
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
