"use strict";
function StreamingMedia() {
}

StreamingMedia.prototype.playAudio = function (params) {
	params.options = params.options || {};
	params.title = params.title || '';
	cordova.exec(params.options.successCallback || null, params.options.errorCallback || null, "StreamingMedia", "playAudio", [params]);
};

StreamingMedia.prototype.stopAudio = function (params) {
    params.options = params.options || {};
    cordova.exec(params.options.successCallback || null, params.options.errorCallback || null, "StreamingMedia", "stopAudio", [params]);
};

StreamingMedia.prototype.playVideo = function (params) {
	params.options = params.options || {};
	params.title = params.title || '';
	cordova.exec(params.options.successCallback || null, params.options.errorCallback || null, "StreamingMedia", "playVideo", [params]);
};
StreamingMedia.prototype.playVideoWithMultiDefinition = function (params) {
	params.options = params.options || {};
	params.title = params.title || '';
	cordova.exec(params.options.successCallback || null, params.options.errorCallback || null, "StreamingMedia", "playVideoWithMultiDefinition", [params]);
};


StreamingMedia.install = function () {
	if (!window.plugins) {
		window.plugins = {};
	}
	window.plugins.streamingMedia = new StreamingMedia();
	return window.plugins.streamingMedia;
};

cordova.addConstructor(StreamingMedia.install);
