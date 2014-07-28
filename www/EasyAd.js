/* 
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

var argscheck = require('cordova/argscheck'),
    exec = require('cordova/exec');

var easyAdExport = {};

/**
 * This enum represents EasyAd's supported ad sizes.  Use one of these
 * constants as the adSize when calling createBannerView.
 * @const
 */
easyAdExport.AD_SIZE = {
  BANNER: 'BANNER',
  IAB_MRECT: 'IAB_MRECT',
  IAB_BANNER: 'IAB_BANNER',
  IAB_LEADERBOARD: 'IAB_LEADERBOARD',
  SMART_BANNER: 'SMART_BANNER'
};

easyAdExport.showBanner =
function(show_or_hide, options, successCallback, failureCallback) {
  var defaults = {
    publisherId: '',
    adSize: 'SMART_BANNER',
    bannerAtTop: false,
    overlap:false,
    offsetTopBar:false,
    isTesting: false,
    adExtras: {
    }
  };

  if(typeof show_or_hide === 'undefined') show_or_hide = true;
  
  if(typeof options === 'object') {
	  for(var k in options) {
		  defaults[k] = options[k];
	  }
  }

  cordova.exec(
      successCallback,
      failureCallback,
      'EasyAd',
      'showBanner',
      [show_or_hide, defaults]
  );
};

easyAdExport.removeBanner = 
function(successCallback, failureCallback) {
	  cordova.exec(
		      successCallback,
		      failureCallback,
		      'EasyAd',
		      'removeBanner',
		      []
		  );
};

easyAdExport.requestInterstitial =
function(options, successCallback, failureCallback) {
  var defaults = {
    publisherId: '',
    isTesting: false
  };

  if(typeof options === 'object') {
	  for(var k in options) {
		  defaults[k] = options[k];
	  }
  }

  cordova.exec(
      successCallback,
      failureCallback,
      'EasyAd',
      'requestInterstitial',
      [defaults]
  );
};

easyAdExport.showInterstitial =
function(successCallback, failureCallback) {
  cordova.exec(
	      successCallback,
	      failureCallback,
	      'EasyAd',
	      'showInterstitial',
	      []
	  );
};

module.exports = easyAdExport;

