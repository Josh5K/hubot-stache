# Description:
#   Hubot plugin to add a moustache to the face of a photo
#
# Dependencies:
#  "request": "^2.74.0"
#  "temp": "^0.8.3"
#
# Configuration:
#  HUBOT_SLACK_TOKEN - Your hubot Slack token (used for uploading attachments to Slack)
#
# Commands:
#   hubot stache me <url> - uploads a moustachified version of the photo in the URL
#
# Notes:
#   Commenting on a Slack photo upload with "hubot stache me" will trigger hubot to upload a moustachified version of that photo
#
# Author:
#   Neufeldtech https://github.com/neufeldtech
_ = require('underscore')
defaultStaches = require('../src/public/defaultStaches.json')

module.exports = (robot) ->
  fs = require "fs"
  path = require "path"
  Barber = require('../src/barber')
  barber = new Barber(robot)
  staches = undefined
  faces = {
    "1": {
      "filename": "jason.jpg",
      "payload": "jason-payload.json"
    }
  }

  robot.router.get "/stacheoverflow", (req, res) ->
    res.sendfile path.resolve("#{__dirname}/../src/public/stacheoverflow.html")
  
  robot.router.get "/stacheoverflow/main.js", (req, res) ->
    res.sendfile path.resolve("#{__dirname}/../src/public/main.js")
  
  robot.router.get "/stacheoverflow/main.css", (req, res) ->
    res.sendfile path.resolve("#{__dirname}/../src/public/main.css")
  
  robot.router.get "/stacheoverflow/face", (req, res) ->
    robot.logger.debug "GET face id: #{req.query.id}"
    filename = faces[req.query.id]['filename']
    if filename
      basepath = path.resolve("#{__dirname}/../src/public/faces/")
      res.sendfile "#{basepath}/#{filename}"
    else 
      res.send(404, '404 Not found');

  robot.router.get "/stacheoverflow/stache", (req, res) ->
    robot.logger.debug "GET stache name: #{req.query.id}"
    staches = robot.brain.get "staches"
    basepath = path.resolve("#{__dirname}/../src/public/templates/")
    stache = _.findWhere(staches, 'id': req.query.id)
    if stache
      res.sendfile("#{basepath}/#{stache.fileName}")
    else
      res.send(404, '404 not found')
  
  robot.router.get "/stacheoverflow/config", (req, res) ->
    if ! req.query.id 
      robot.logger.debug "GET config id: #{req.query.id}"
      staches = robot.brain.get "staches"
      res.json(staches)
    else
      robot.logger.debug "GET all config objects"
      stache = _.findWhere(staches, 'id': req.query.id)
      if !stache
        res.send(404, '404 not found')
      else
        res.json(stache)
  
  robot.router.get "/stacheoverflow/config/flush", (req, res) ->
    robot.brain.remove "staches"
    res.send('Reset all stache config to defaults')
    robot.brain.set "staches", defaultStaches
    robot.logger.debug "Resetting all stache config to default"

  
  robot.router.get "/stacheoverflow/testdata", (req, res) ->
    robot.logger.debug "GET testdata id: #{req.query.id}"
    filename = faces[req.query.id]['payload']
    if filename
      basepath = path.resolve("#{__dirname}/../src/public/testdata")
      res.sendfile "#{basepath}/#{filename}"
    else 
      res.send(404, '404 Not found');



  robot.catchAll (msg) ->
    moustacheRegex = new RegExp(robot.name + ".*stache me", "i")
    isRequestToBeMoustachified = moustacheRegex.test(msg.message.text)
    if /file_comment|file_share/i.test(msg.message.subtype) and /image/i.test(msg.message.file.mimetype) and isRequestToBeMoustachified
      barber.downloadSlackFile msg.message.file.url_private_download, (err, attachmentFilename) ->
        if err
          return robot.messageRoom msg.message.file.channels[0], "I had an error trying to moustachify you :sob: #{err}"
        barber.moustachify attachmentFilename, (err, moustacheFilename) ->
          if err
            return robot.messageRoom msg.message.file.channels[0], "I had an error trying to moustachify you :sob: #{err}"
          contentOpts =
            file: fs.createReadStream(moustacheFilename)
            title: "Here ya go, sport"
            channels: msg.message.file.channels[0] #post back to the first channel that this file was shared in
          robot.adapter.client.web.files.upload "sport.#{moustacheFilename.split('.').pop()}", contentOpts, (err, res) ->
            fs.unlink(attachmentFilename)
            fs.unlink(moustacheFilename)
            if err or res.ok != true
              return robot.messageRoom msg.message.file.channels[0], "I had an error trying to moustachify you :sob: I could not upload the image to slack. #{err}"
            return
