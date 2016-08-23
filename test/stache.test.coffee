fs = require('fs')
http = require('http')
Promise= require('bluebird')
co     = require('co')
expect = require('chai').expect
assert = require('chai').assert
sinon = require('sinon')

{TextMessage, CatchAllMessage} = require.main.require 'hubot'

Helper = require('hubot-test-helper')
helper = new Helper('../scripts/stache.coffee')


describe 'stache hubot script', ->
  describe 'attachment moustachifier', ->
    context 'on success', ->
      beforeEach ->
        @room = helper.createRoom(httpd: false)
        @room.robot.adapter.client =
          web:
            files:
              upload: (filename, options, cb) ->
                cb null, { ok: true }
        @nock = require('nock')
        @nock.disableNetConnect()
        @nock('http://files.slack.test')
          .get('/get/attachment/cat.jpg')
          .reply(200, (uri, requestBody) ->
            return fs.createReadStream(__dirname + '/img/cat.jpg'))
        @nock('https://funnyface.neufeldtech.com')
          .post('/upload')
          .reply(200, (uri, requestBody) ->
            return fs.createReadStream(__dirname + '/img/cat.jpg'))

        fileCommentMessage = new CatchAllMessage(require('./file_comment_message.json'))
        @room.robot.receive fileCommentMessage

        co =>
          yield new Promise.delay(100)

      afterEach ->
        @nock.cleanAll()
        @nock.enableNetConnect()


      it 'should upload the moustachified version without error messages', ->
        #write this eventually
        expect(@room.messages).to.eql []

    context 'on failure to download slack attachment', ->
      beforeEach ->
        @room = helper.createRoom(httpd: false)
        @nock = require('nock')
        @nock.disableNetConnect()
        @nock('http://files.slack.test')
          .get('/get/attachment/cat.jpg')
          .replyWithError("Woops, could not download slack attachment")
        fileCommentMessage = new CatchAllMessage(require('./file_comment_message.json'))
        @room.robot.receive fileCommentMessage

        co =>
          yield new Promise.delay(100)

      afterEach ->
        @nock.cleanAll()
        @nock.enableNetConnect()


      it 'should send error message', ->
        #write this eventually
        expect(@room.messages).to.eql [
          ['hubot', 'I had an error trying to moustachify you :sob: There was an error getting the image attachment from slack :sob: Error: Woops, could not download slack attachment']
        ]

    context 'on failure to moustachify the image', ->
      beforeEach ->
        @room = helper.createRoom(httpd: false)
        @nock = require('nock')
        @nock.disableNetConnect()
        @nock('http://files.slack.test')
          .get('/get/attachment/cat.jpg')
          .reply(200, (uri, requestBody) ->
            return fs.createReadStream(__dirname + '/img/cat.jpg'))
        @nock('https://funnyface.neufeldtech.com')
          .post('/upload')
          .replyWithError('Bro, I could not even make you a moustache')
        fileCommentMessage = new CatchAllMessage(require('./file_comment_message.json'))
        @room.robot.receive fileCommentMessage

        co =>
          yield new Promise.delay(100)

      afterEach ->
        @nock.cleanAll()
        @nock.enableNetConnect()


      it 'should send error message', ->
        #write this eventually
        expect(@room.messages).to.eql [
          ['hubot', 'I had an error trying to moustachify you :sob: There was an error with the moustachification: Error: Bro, I could not even make you a moustache']
        ]

    context 'on failure to upload slack attachment', ->
      beforeEach ->
        @room = helper.createRoom(httpd: false)
        @room.robot.adapter.client =
          web:
            files:
              upload: (filename, options, cb) ->
                cb "this is an error during the upload. boo hoo."
        @nock = require('nock')
        @nock.disableNetConnect()
        @nock('http://files.slack.test')
          .get('/get/attachment/cat.jpg')
          .reply(200, (uri, requestBody) ->
            return fs.createReadStream(__dirname + '/img/cat.jpg'))
        @nock('https://funnyface.neufeldtech.com')
          .post('/upload')
          .reply(200, (uri, requestBody) ->
            return fs.createReadStream(__dirname + '/img/cat.jpg'))
        fileCommentMessage = new CatchAllMessage(require('./file_comment_message.json'))
        @room.robot.receive fileCommentMessage

        co =>
          yield new Promise.delay(100)

      afterEach ->
        @nock.cleanAll()
        @nock.enableNetConnect()


      it 'should send error message', ->
        #write this eventually
        expect(@room.messages).to.eql [
          ['hubot', 'I had an error trying to moustachify you :sob: I could not upload the image to slack. this is an error during the upload. boo hoo.']
        ]

  describe 'url moustachifier', ->
    context 'on success', ->
      beforeEach ->
        @room = helper.createRoom(httpd: false)

      it 'should respond with moustachified URL', ->
        @room.user.say('jordan.neufeld', '@hubot stache me https://raw.githubusercontent.com/neufeldtech/funnyface/master/docs/img/barack.jpg').then =>
          expect(@room.messages).to.eql [
            ['jordan.neufeld', '@hubot stache me https://raw.githubusercontent.com/neufeldtech/funnyface/master/docs/img/barack.jpg']
            ['hubot', 'https://funnyface.neufeldtech.com/api/v1/image?url=https://raw.githubusercontent.com/neufeldtech/funnyface/master/docs/img/barack.jpg']
          ]
