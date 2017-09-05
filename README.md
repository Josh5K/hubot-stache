hubot-stache
================
[![npm version](https://badge.fury.io/js/hubot-stache.svg)](https://badge.fury.io/js/hubot-stache)

Hubot plugin to add a moustache to the face of a photo. This plugin uses [AWS Rekognition](https://aws.amazon.com/rekognition/) for face detection and ImageMagick (on the hubot server) for layering the stache on the image.

Currently this hubot plugin only works with Slack. If you would like to help port it to other platforms, submit a [Pull Request](https://github.com/neufeldtech/hubot-stache/pulls/)

## Prerequisites
You will need [hubot-redis-brain](https://github.com/hubotio/hubot-redis-brain) installed and working before installation

## Installation
**This hubot script requires version 4+ of the [hubot-slack](https://github.com/slackhq/hubot-slack) slack adapter package**
* [Install ImageMagick](https://www.imagemagick.org/script/download.php) on your hubot server
* Run the ```npm install``` command

```
npm install hubot-stache --save
```

* Add the following code in your external-scripts.json file.

```
["hubot-stache"]
```

* Be sure your AWS Keys are in the environment. You will need to grant AWS credentials with permissions to the **Rekognition** service.

```
export HUBOT_AWS_REKOGNITION_ACCESS_KEY_ID="12345678"
export HUBOT_AWS_REKOGNITION_SECRET_ACCESS_KEY="abc123456def"
```

## Note
This script uses some of the same listeners as ```hubot-google-images``` which is installed by default when using the [Yeoman generator](https://github.com/github/generator-hubot/blob/883d42092701634720df52451d70977b215f1f3c/generators/app/index.js). If you are not using ```hubot-google-images```, you may want to remove it from your external-scripts.json file.

## Usage
- Upload a photo to slack (at least 500px x 300px) that contains at least one face
- Add a comment to the photo upload ```@hubot stache me```
- Hubot will upload a moustachified version of the photo to Slack

## Tests
- Use node 6.2+
- ```npm install```
- ```npm test```
