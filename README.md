# Cordova Streaming Media plugin

for iOS and Android, by [Nicholas Hutchind](https://github.com/nchutchind)

1. [Description](https://github.com/nchutchind/Streaming-Media-Cordova-Plugin#1-description)
2. [Usage](https://github.com/nchutchind/Streaming-Media-Cordova-Plugin#2-usage)

## 1. Description

This plugin allows you to stream audio and video in a fullscreen, native player on iOS and Android.

* Works with PhoneGap >= 3.0.

### iOS specifics
* Uses the MPMoviePlayerController.
* Tested on iOS 7. (If someone has an iOS 6 device, please report back to me how it does.)

### Android specifics
* Uses VideoView and MediaPlayer.
* Creates two activities in your AndroidManifest.xml file.
* Tested on Android 4.0+. (If someone has a Gingerbread device, please report back to me how it does.)

## 2. Usage

```javascript
  var videoUrl = STREAMING_VIDEO_URL;

  // Just play a video
  window.plugins.streamingMedia.playVideo(videoUrl);

  // Play a video with callbacks
  var videoUrls = ["http://7xloz0.com2.z0.glb.qiniucdn.com/video%2Ftronclass.mp4","http://7xloz0.com2.z0.glb.qiniucdn.com/video%2Ftronclass.mp4"];
  var options = {
    successCallback: function(infoDic) {
  		  console.log(infoDic);
        // infoDic maybe contained keys below:
        //{"playCallBack",floatTime}, {"pauseCallBack",floatTime}, {"seekingCallBack",floatTime}, {"seekedCallBack",floatTime}, {"eachCallBack",floatTime}, {"finishedCallBack",floatTime}
  	 },
  	errorCallback: function(errMsg) {
  	   console.log("Error! " + errMsg);
  	}
  };
  window.plugins.streamingMedia.playVideo(videoUrls,true,options);



// play muti-definition video

   var videoUrls =  ["QVGA|http://7xloz0.com2.z0.glb.qiniucdn.com/tronclass.mp4", "VGA|http://7xloz0.com2.z0.glb.qiniucdn.com/tronclass%20copy.mp4"];
            
            var options = {
            successCallback: function(infoDic) {
            console.log(infoDic);
            // infoDic maybe contained keys below:
            //{"playCallBack",floatTime}, {"pauseCallBack",floatTime}, {"seekingCallBack",floatTime}, {"seekedCallBack",floatTime}, {"eachCallBack",floatTime}, {"finishedCallBack",floatTime}
            },
            errorCallback: function(errMsg) {
            console.log("Error! " + errMsg);
            }
            };
            window.plugins.streamingMedia.playVideoWithMultiDefinition(videoUrls,true,options);


  var audioUrl = STREAMING_AUDIO_URL;

  // Play an audio file (not recommended, since the screen will be plain black)
  window.plugins.streamingMedia.playAudio(audioUrl);

  // Play an audio file with options (all options optional)
  var options = {
    bgColor: "#FFFFFF",
    bgImage: "<SWEET_BACKGROUND_IMAGE>",
    bgImageScale: "fit",
    initFullscreen: false, // true(default)/false iOS only
    successCallback: function() {
      console.log("Player closed without error.");
    },
    errorCallback: function(errMsg) {
      console.log("Error! " + errMsg);
    }
  };
  window.plugins.streamingMedia.playAudio(audioUrl, options);


  // Stop current audio
  window.plugins.streamingMedia.stopAudio();

```
