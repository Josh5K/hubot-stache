hubot-stache
================
[![npm version](https://badge.fury.io/js/hubot-stache.svg)](https://badge.fury.io/js/hubot-stache)

Hubot plugin to add a moustache to the face of a photo.

Currently this hubot plugin only works with Slack. If you would like to help port it to other platforms, submit a [Pull Request](https://github.com/neufeldtech/hubot-stache/pulls/)

## Installation
**This hubot script requires version 4+ of the [hubot-slack](https://github.com/slackhq/hubot-slack) slack adapter package**

* Run the ```npm install``` command

```
npm install hubot-stache --save
```

* Add the following code in your external-scripts.json file.

```
["hubot-stache"]
```
## Note
This script uses some of the same listeners as ```hubot-google-images``` which is installed by default when using the [Yeoman generator](https://github.com/github/generator-hubot/blob/883d42092701634720df52451d70977b215f1f3c/generators/app/index.js). If you are not using ```hubot-google-images```, you may want to remove it from your external-scripts.json file.

## Usage
### Method One
- Upload a photo to slack (at least 500px x 300px) that contains at least one face
- Add a comment to the photo upload ```@hubot stache me```
- Hubot will upload a moustachified version of the photo to Slack

### Method Two
- ```@hubot stache me https://raw.githubusercontent.com/neufeldtech/funnyface/master/docs/img/barack.jpg```
- Hubot will respond with a moustachified version of the photo

## Tests
- Use node 6.2+
- ```npm install```
- ```npm test```
