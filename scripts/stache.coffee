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
module.exports = (robot) ->
  fs = require "fs"
  Barber = require('./barber')
  barber = new Barber()

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
