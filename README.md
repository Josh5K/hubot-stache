hubot-stache
================

Hubot plugin to add a moustache to the face of a photo

**Note:**
Currently this hubot plugin only works with Slack. If you would like to help port it to other platforms, submit a [Pull Request](https://github.com/neufeldtech/hubot-stache/pulls/)

## Installation


* Run the ```npm install``` command

```
npm install hubot-stache --save
```

* Add the following code in your external-scripts.json file.

```
["hubot-stache"]
```

## Usage

### Method one

- Upload a photo to slack (at least 500px x 300px) that contains at least one face
- Add a comment to the photo upload ```@hubot stache me```
- Hubot will upload a moustachified version of the photo to Slack

### Method two
- Use the **hubot stache me** command with a URL of a photo (at least 500px x 300px)
```
@hubot stache me https://raw.githubusercontent.com/neufeldtech/funnyface/master/docs/img/barack.jpg
```
- Hubot will upload a moustachified version of the photo to Slack
