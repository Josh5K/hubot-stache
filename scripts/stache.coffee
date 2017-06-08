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
_ = require "underscore"
fs = require "fs"
path = require "path"
shortid = require "shortid"
defaultStaches = require('../src/public/config/stache/default.json')
faceImageDirectory = path.resolve("#{__dirname}/../src/public/faces/")
stacheImageDirectory = path.resolve("#{__dirname}/../src/public/templates/")
faceConfigDirectory = path.resolve("#{__dirname}/../src/public/config/face/")
stacheConfigDirectory = path.resolve("#{__dirname}/../src/public/config/stache/")

module.exports = (robot) ->
  
  Barber = require('../src/barber')
  barber = new Barber(robot)
  staches = undefined

  # GET /stacheoverflow - returns index page
  robot.router.get "/stacheoverflow", (req, res) ->
    res.sendfile path.resolve("#{__dirname}/../src/public/stacheoverflow.html")
  
  # POST /stacheoverflow/image/face - create a face
  robot.router.post "/stacheoverflow/image/face", (req, res) ->
    if ! req.files || ! req.files.image
      res.send(400, 'No file sent with image key')
    else
      fs.createReadStream(req.files.image['path']).pipe(fs.createWriteStream("#{faceImageDirectory}/#{req.files.image['originalFilename']}"));
      robot.logger.debug "Wrote new file to #{faceImageDirectory}/#{req.files.image['originalFilename']}"
      res.send('thanks')

  # GET /stacheoverflow/image/face/:id - returns a face image
  robot.router.get "/stacheoverflow/image/face/:id", (req, res) ->
    robot.logger.debug "GET face id: #{req.params.id}"
    faces = robot.brain.get "faces"
    face = _.findWhere(faces, 'id': req.params.id)
    if face
      basepath = path.resolve("#{__dirname}/../src/public/faces/")
      res.sendfile "#{basepath}/#{face.fileName}"
    else 
      res.send(404, '404 Not found');

  # POST /stacheoverflow/image/stache - create a stache (must send as multipart upload with file as the 'image' parameter)
  robot.router.post "/stacheoverflow/image/stache", (req, res) ->
    if ! req.files || ! req.files.image
      res.send(400, 'No file sent with image key')
    else
      fs.createReadStream(req.files.image['path']).pipe(fs.createWriteStream("#{stacheImageDirectory}/#{req.files.image['originalFilename']}"));
      robot.logger.debug "Wrote new file to #{stacheImageDirectory}/#{req.files.image['originalFilename']}"
      staches = robot.brain.get "staches"
      staches.push({
      "id": shortid.generate(),
      "fileName": req.files.image['originalFilename']
      })
      robot.brain.set "staches", staches
      robot.logger.debug "Current staches: #{JSON.stringify(staches)}"
      res.send('thanks')

  # GET /stacheoverflow/image/stache/:id - returns a stache image
  robot.router.get "/stacheoverflow/image/stache/:id", (req, res) ->
    robot.logger.debug "GET stache id: #{req.params.id}"
    staches = robot.brain.get "staches"
    stache = _.findWhere(staches, 'id': req.params.id)
    if stache
      basepath = path.resolve("#{__dirname}/../src/public/templates/")
      res.sendfile("#{basepath}/#{stache.fileName}")
    else
      res.send(404, '404 not found')
  
  # POST /stacheoverflow/config/stache - create a stache config (must send as JSON). Overwrites staches of same ID
  robot.router.post "/stacheoverflow/config/stache", (req, res) ->
    robot.logger.debug "Creating stache #{stache}"
    stache = req.body
    staches = robot.brain.get "staches"
    originalStache = _.findWhere(staches, id: stache.id)
    if originalStache
      _.extend(originalStache, stache)
      robot.logger.debug "Overwrote existing stache id #{stache.id} with object #{JSON.stringify(stache)}"
    else
      staches.push(stache)
      robot.logger.debug "Added stache to collection #{JSON.stringify(stache)}"
    robot.brain.set "staches", staches
    robot.logger.debug "Current staches: #{JSON.stringify(staches)}"
    res.send('thanks')

  # GET /stacheoverflow/config/face - returns all face config data
  robot.router.get "/stacheoverflow/config/face", (req, res) ->
    robot.logger.debug "GET all face config objects"
    faces = robot.brain.get "faces"
    res.json(faces)

  # GET /stacheoverflow/config/face/:id - returns face config data for id
  robot.router.get "/stacheoverflow/config/face/:id", (req, res) ->
    robot.logger.debug "GET face config id: #{req.params.id}"
    faces = robot.brain.get "faces"
    face = _.findWhere(faces, 'id': req.params.id)
    if face
      res.json(face)
    else
      res.send(404, '404 not found')
  
  # GET /stacheoverflow/config/stache - returns all stache config data
  robot.router.get "/stacheoverflow/config/stache", (req, res) ->
    robot.logger.debug "GET all stache config objects"
    staches = robot.brain.get "staches"
    res.json(staches)
    
  # GET /stacheoverflow/config/stache/:id - returns stache config data for id
  robot.router.get "/stacheoverflow/config/stache/:id", (req, res) ->
    robot.logger.debug "GET stache config id: #{req.params.id}"
    staches = robot.brain.get "staches"
    stache = _.findWhere(staches, 'id': req.params.id)
    if stache
      res.json(stache)
    else
      res.send(404, '404 not found')
  
  # DELETE /stacheoverflow/config/stache/:id - deletes stache config for id
  robot.router.delete "/stacheoverflow/config/stache/:id", (req, res) ->
    staches = robot.brain.get "staches"
    stache = _.findWhere(staches, 'id': req.params.id)
    if stache
      staches = _.without(staches, stache)
      robot.brain.set "staches", staches
      robot.logger.debug "Removing stache config with id #{stache.id}"
      res.send("Removed stache with id #{stache.id}")
    else
      res.send(404, "Stache not found")

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
