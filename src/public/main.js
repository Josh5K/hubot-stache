$(document).ready(function () {

  var testSubject = 1

  var configData, stacheOffsetX, stacheOffsetY, feature, scaleFactor, stacheX, stacheY, stacheWidth, stacheHeight, x_nose, y_nose, x_mouthLeft, y_mouthLeft, x_mouthRight, y_mouthRight, x_eyeLeft, y_eyeLeft, x_eyeRight, y_eyeRight
  var baseCanvas = document.getElementById('baseCanvas');
  var overlayCanvas = document.getElementById('overlayCanvas');
  var facectx = baseCanvas.getContext('2d');
  var stachectx = overlayCanvas.getContext('2d');
  facectx.scale(0.5, 0.5)
  stachectx.scale(0.5, 0.5)
  var face = new Image();
  var stache = new Image();
  function drawConfigData() {
     // -geometry (stache.width * scaleFactor)x+(x_mouthLeft)
     
     stacheOffsetX = Math.floor(stacheX - eval(`x_${feature}`))
     stacheOffsetY = Math.floor(stacheY - eval(`y_${feature}`))
     console.log(`Stache X position ${stacheX}`) //Unknown
     console.log(`Stache Y position ${stacheY}`) //Unknown
     console.log(`Slider X value ${document.getElementById("h-slider").value}`) //N/A
     console.log(`Slider Y value ${document.getElementById("v-slider").value}`) //N/A
     console.log(`Feature X position ${eval(`x_${feature}`)}`) //known
     console.log(`Feature Y position ${eval(`y_${feature}`)}`) //known
     console.log(`Stache X Offset ${stacheOffsetX}`) //known
     console.log(`Stache Y Offset ${stacheOffsetY}`) //known
     console.log(`Formula: (stache.width * scaleFactor)x+(stacheOffsetX + x_feature)+(stacheOffsetY + y_feature)`)
     console.log(`---`)

    // document.getElementById('config-data').innerHTML  = `convert /home/jordan/dev/nubot/node_modules/hubot-stache/src/public/faces/jason.jpg \
    //  /home/jordan/dev/nubot/node_modules/hubot-stache/src/public/templates/stache.png \
    //  -geometry ${Math.floor(stache.width * scaleFactor)}x+${Math.floor(stacheOffsetX + eval(`x_${feature}`))}+${Math.floor(stacheOffsetY + eval(`y_${feature}`))} -composite \
    //  /tmp/jason.jpg`
     configData = { "name": "stache.png", "featureAnchor": feature, "offsetX": stacheOffsetX, "offsetY": stacheOffsetY, "scaleFactor": scaleFactor }
     document.getElementById('config-data').innerHTML = JSON.stringify(configData)

  }
  function resetSliderPositions(x, y) {
    document.getElementById("h-slider").value = x
    document.getElementById("v-slider").value = y
  }
  face.onload = function () {
    facectx.drawImage(face, 0, 0);
    $.getJSON(`/stacheoverflow/testdata?id=${testSubject}`, function (data) {
      facedata = data.FaceDetails[0]
      facectx.fillStyle = "#FFFF00";
      var landmarks = facedata.Landmarks;
      var nose = _.findWhere(landmarks, {
        'Type': 'nose'
      });
      x_nose = nose.X * face.width;
      y_nose = nose.Y * face.height;
      facectx.fillRect(x_nose, y_nose, 5, 5);

      var mouthLeft = _.findWhere(landmarks, {
        'Type': 'mouthLeft'
      });

      x_mouthLeft = mouthLeft.X * face.width;
      y_mouthLeft = mouthLeft.Y * face.height;
      facectx.fillRect(x_mouthLeft, y_mouthLeft, 5, 5);

      var mouthRight = _.findWhere(landmarks, {
        'Type': 'mouthRight'
      });
      x_mouthRight = mouthRight.X * face.width;
      y_mouthRight = mouthRight.Y * face.height;
      var mouthWidth = x_mouthRight - x_mouthLeft;
      facectx.fillRect(x_mouthRight, y_mouthRight, 5, 5);


      var eyeLeft = _.findWhere(landmarks, {
        'Type': 'eyeLeft'
      });
      x_eyeLeft = eyeLeft.X * face.width;
      y_eyeLeft = eyeLeft.Y * face.height;
      facectx.fillRect(x_eyeLeft, y_eyeLeft, 5, 5);

      var eyeRight = _.findWhere(landmarks, {
        'Type': 'eyeRight'
      });
      x_eyeRight = eyeRight.X * face.width;
      y_eyeRight = eyeRight.Y * face.height;
      facectx.fillRect(x_eyeRight, y_eyeRight, 5, 5);

      stache.onload = function () {
        stacheX = x_mouthLeft
        stacheY = y_mouthLeft
        scaleFactor = 1
        feature = $("#feature-select").val()
        stacheWidth = stache.width
        stacheHeight = stache.height
        stachectx.drawImage(stache, stacheX, stacheY);
      };
      stache.src = '/stacheoverflow/stache?name=stache.png';
    }); //end get testdata json
  };
  face.src = `/stacheoverflow/face?id=${testSubject}`;

  $("#h-slider").on("input change", function () {
    stacheX = this.value
    stachectx.clearRect(0, 0, 1280, 960)
    stachectx.drawImage(stache, stacheX, stacheY, stacheWidth, stacheHeight);
    drawConfigData()
  })
  $("#v-slider").on("input change", function () {
    stacheY = this.value
    stachectx.clearRect(0, 0, 1280, 960)
    stachectx.drawImage(stache, stacheX, stacheY, stacheWidth, stacheHeight);
    drawConfigData()
  })
  $("#s-slider").on("input change", function () {
    scaleFactor = this.value
    stacheWidth = stache.width * scaleFactor
    stacheHeight = stache.height * scaleFactor
    feature = $('#feature-select').val()
    stacheX = eval(`x_${feature}`)
    stacheY = eval(`y_${feature}`)
    resetSliderPositions(stacheX, stacheY)
    stachectx.clearRect(0, 0, 1280, 960)
    stachectx.drawImage(stache, stacheX, stacheY, stacheWidth, stacheHeight);
    drawConfigData()
  })
  $("#feature-select").on("input change", function () {
    stachectx.clearRect(0, 0, 1280, 960)
    feature = this.value
    stacheX = eval(`x_${feature}`)
    stacheY = eval(`y_${feature}`)
    resetSliderPositions(stacheX, stacheY)
    stachectx.drawImage(stache, stacheX, stacheY, stacheWidth, stacheHeight);
    drawConfigData()
  })
})
