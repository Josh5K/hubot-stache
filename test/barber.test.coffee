chai = require('chai')
expect = require('chai').expect
fs = require('fs')

Barber = require('../scripts/barber')
barber = new Barber()

describe 'barber module', ->
  describe 'barber', ->
    describe '.downloadSlackFile', ->
      context 'on success', ->
        beforeEach ->
          @nock = require('nock')
          # @nock.cleanAll()
          @nock.disableNetConnect()
          @nock('http://files.slack.test')
            .get('/get/attachment/cat.jpg')
            .reply(200, (uri, requestBody) ->
              return fs.createReadStream(__dirname + '/img/cat.jpg'))
        afterEach ->
          @nock.cleanAll()
          @nock.enableNetConnect()
        it 'should return filename with same extension after downloading file', (done) ->
          barber.downloadSlackFile "http://files.slack.test/get/attachment/cat.jpg", (err, attachmentFilename) ->
            expect(attachmentFilename).to.match /.*\.jpg/
            done()

      context 'on failure to connect', ->
        beforeEach ->
          @nock = require('nock')
          # @nock.cleanAll()
          @nock.disableNetConnect()
          @nock('http://files.slack.test')
            .get('/get/attachment/error.jpg')
            .replyWithError('woops, you broke it')
        afterEach ->
          @nock.cleanAll()
          @nock.enableNetConnect()
        it 'should return error message', (done) ->
          barber.downloadSlackFile "http://files.slack.test/get/attachment/error.jpg", (err, attachmentFilename) ->
            expect(err).to.match /There was an error getting the image attachment from slack :sob:/
            done()

      context 'on failure due to http status code error', ->
        beforeEach ->
          @nock = require('nock')
          # @nock.cleanAll()
          @nock.disableNetConnect()
          @nock('http://files.slack.test')
            .get('/get/attachment/error.jpg')
            .reply(404, "wooooops not found bro")
        afterEach ->
          @nock.cleanAll()
          @nock.enableNetConnect()
        it 'should return error message', (done) ->
          barber.downloadSlackFile "http://files.slack.test/get/attachment/error.jpg", (err, attachmentFilename) ->
            expect(err).to.match /There was an error getting the image attachment from slack :sob:/
            done()

    describe '.moustachify', ->
      context 'on success', ->
        beforeEach ->
          @nock = require('nock')
          # @nock.cleanAll()
          @nock.disableNetConnect()
          @nock('https://funnyface.neufeldtech.com')
            .post('/upload')
            .reply(200, (uri, requestBody) ->
              return fs.createReadStream(__dirname + '/img/cat.jpg'))
        afterEach ->
          @nock.cleanAll()
          @nock.enableNetConnect()
        it 'should return filename if successfully moustachified image', (done) ->
          barber.moustachify __dirname + '/img/cat.jpg', (err, moustacheFilename) ->
            expect(moustacheFilename).to.match /.*\.jpg/
            done()

      context 'on failure to connect', ->
        beforeEach ->
          @nock = require('nock')
          # @nock.cleanAll()
          @nock.disableNetConnect()
          @nock('https://funnyface.neufeldtech.com')
            .post('/upload')
            .replyWithError('oops, could not moustacheify image')
        afterEach ->
          @nock.cleanAll()
          @nock.enableNetConnect()
        it 'should return error message', (done) ->
          barber.moustachify __dirname + '/img/cat.jpg', (err, moustacheFilename) ->
            expect(err).to.match /There was an error with the moustachification/
            done()

      context 'on failure due to http 400', ->
        beforeEach ->
          @nock = require('nock')
          # @nock.cleanAll()
          @nock.disableNetConnect()
          @nock('https://funnyface.neufeldtech.com')
            .post('/upload')
            .reply(400, { success: false })
        afterEach ->
          @nock.cleanAll()
          @nock.enableNetConnect()
        it 'should return error message', (done) ->
          barber.moustachify __dirname + '/img/cat.jpg', (err, moustacheFilename) ->
            expect(err).to.match /There was an error with the moustachification/
            done()
