/*
   loadappliance.js: the workhorse of the loader
   $Id$

   Copyright 2010-2012 Portland Transport

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Authors:
   Matt Conway: main code
   Chris Smith: Raspberry Pi version

*/

// The number of datastores available
DATASTORES = 3;

// The amount of time to wait for a server to respond (seconds)
TIMEOUT = 20;

// The URL of the error display page
ERR_HANDLER = "https://transitappliance.com/error_service";

function convertUrlToHttps(url) {
   return url;
}

function confirmNetwork(hwid, callback) {
	//show 'not connected' until we get a successful return from one of our repositories
	testURLs("FF:FF:FF:FF:FF:FF", function() {
		jQuery("img#connection_icon").attr("src","connected_512x512.png"); 
		setTimeout(function () {
	  		jQuery("div#connection_status").remove();
	  		jQuery("div#fixed").show();
	  		callback();
	  }, 2000);
	}, 0);
}

function datastore_count(n) {
	return (n % DATASTORES) + 1;
}


// Returns the URL for datastore n, hwid hwid
function datastore(n, hwid) { 
    var repNumber = datastore_count(n)+5;
    return 'https://repository' + repNumber + '.transitappliance.com/configuration/MAC:' + hwid;
}

// Log to the log
function wtolog(msg) {
    var log = document.getElementById("log");
    var m = document.createElement("p");
    m.innerHTML = msg;
    log.appendChild(m);

    // Scroll to the latest log entry
    $(document).scrollTop($(m).position().top);
}

// Create a JSON.parse if it doesn't exist already
function createJSONObj() {
    if (typeof JSON == 'undefined') {
	wtolog('Browser lacks native JSON, fixing...');
	JSON = {'parse': function(data) { return json_parse(data); }}
    }
}

function showError(err, args) {
    // Get rid of the 'Loading, please wait...'
    var wait = document.getElementById('wait');
    wait.setAttribute('style', 'display: none');

    // Add the error to the data for transmission
    args['error'] = err;

    // Fetch the JSON error
    // We can't use $.get b/c we need the jQuery the error handler
    $.ajax({
	method: 'GET',
	url: ERR_HANDLER,
	data: args,
	dataType: 'json',
	timeout: TIMEOUT*1000,
	success: function (err) {	        
	    // Parse the JSON
	    wtolog('received from err server: ' + err.title + ': ' + err.message);
	    
	    // For some reason, we get a weird MODIFICATION_NOT_ALLOWED 
	    // error from some webkit browsers (Arora, Infocast browser, 
	    // but not Chrome) if we try to do this after setting the innerHTML.
	    var eblock = document.getElementById('err');
	    eblock.style.display = 'block';

	    // We should have an error message now.
	    document.getElementById('errmsg').innerHTML = err.message;
	    document.getElementById('errhead').innerHTML = err.title;
	    
	    // Update the offset for the log
	    setLogOffset();
	    
	    // Write something to the log to make sure it's scrolled 
	    // to the bottom
	    wtolog('error shown');

	    // Put it in the title bar; it's generally not shown
	    // but it won't hurt
	    document.title = 'Transit Appliance - ' + err.title;
	},
	error: function (r, status) {
	    wtolog('Could not connect to error server: ' + status);
            var nc = document.getElementById('noconnection');
            nc.style.display = 'block';

	    // Update the offset for the log
	    setLogOffset();
	    
	    // Write something to the log to make sure it's scrolled 
	    // to the bottom
	    wtolog('error shown');

            return;
	}
    });
}

// i is the datastore to query
// If the datastore responds incorrectly, 
function testURLs(hwid, successCallback, i) {
    if (i == undefined) var i = 0;

    // Try to find a URL
    $.ajax({
			method: 'GET',
			// can't use data: b/c it is for query string params, and this is path
			// type param (i.e. no ?hwid=)
			url: datastore(i, hwid),
			dataType: 'json',
			timeout: TIMEOUT*1000,
			success: function (data) {
		    // If any of these are true, the data is no good,
		    // so we call this function again for the next datastore
		    if (data == null || 'error' in data || !('urls' in data) || data.url == 'undefined') {
		    	//wtolog('problem with return data ' + i);
					// Call it again, Sam.
					testURLs(hwid, successCallback, i + 1);
					return;
		    }	
		    successCallback();
			},
			error: function (r, status) {
			    // try the next one
			    //wtolog('error on URL test ' + i);
			    testURLs(hwid, successCallback, i + 1);
			}
    });
}

// i is the datastore to query
// If the datastore responds incorrectly, 
function getURLs(hwid, successCallback, i) {
    if (i == undefined) var i = 0;

    // Check we haven't reached max datastores

    if (i > DATASTORES*10) {
			showError('noconfig', {'hwid':hwid});
			return;
    }

		setTimeout(function(){
	    // Wait one second then try to find a URL
	    $.ajax({
				method: 'GET',
				// can't use data: b/c it is for query string params, and this is path
				// type param (i.e. no ?hwid=)
				url: datastore(i, hwid),
				cache: false,
				dataType: 'json',
				timeout: TIMEOUT*1000,
				success: function (data) {
				    // If any of these are true, the data is no good,
				    // so we call this function again for the next datastore
				    if (data == null) {
					wtolog('no data returned by Datasource ' + datastore_count(i));
					// Call it again, Sam.
					getURLs(hwid, successCallback, i + 1);
					return;
				    }	
				    if ('error' in data) {
					wtolog('Datasource ' + datastore_count(i) + ' error in the data returned: ' + data.error);
					// Call it again, Sam.
					getURLs(hwid, successCallback, i + 1);
					return;
				    }
				    if (!('urls' in data)) {
					wtolog('Datasource ' + datastore_count(i) + ' responds but has no URLs to suggest');
					getURLs(hwid, successCallback, i + 1);
					return;
				    }
				    if (data.url == 'undefined') {
					wtolog('Datasource ' + datastore_count(i) + " responds with URL 'undefined'");
					getURLs(hwid, successCallback, i + 1);
					return;
				    }
			
				    // Run the callback
				    var html = '<table>';
				    var len = data.urls.length;
				    for (var c = 0; c < len; c++) {
				        data.urls[c].app_url = convertUrlToHttps(data.urls[c].app_url);
				        data.urls[c].img_url = convertUrlToHttps(data.urls[c].img_url);
						html += '<tr><td>' + data.urls[c].app_url + '</td>';
						html += '<td>' + data.urls[c].img_url + '</td></tr>';
				    }
				    html += '</table>';
				    wtolog('Datasource ' + datastore_count(i) + ' suggests URLs: ' + html);
				    successCallback(data.urls);
				},
				error: function (r, status) {
				    // As before, if the response was no good, try next
				    wtolog('Datasource ' + datastore_count(i) + ' errors with status ' + status);
			
				    // try the next one
				    getURLs(hwid, successCallback, i + 1);
				}
	    });
	  }, 1000);
}

// callback gets url that is clean and up
function chooseURL (urls, callback, index) {
    if (index == undefined) {
			index = 0;
    }

    // >= b/c index is from 0, length from 1
    if (index >= urls.length*10) {
			showError('nourls', {});
			return null;
    }

    var url = urls[index % urls.length];

    // ping URL, then callback
	pingURL(
	    url,
	    function (availUrl, status) {
				if (status == 'up') {
				    // URL is clean and up
				    callback(availUrl);
				}
				else {
				    // not up
				    // These vars should be passed down into
				    // the closure
				    chooseURL(urls, callback, index + 1)
				}
	    }
	);


}   



// callback gets URL, status ('up' or 'down') in that order
function pingURL(url, callback) {
    // append a random number, to prevent browsers caching the ping image
    var rand = Math.random();
    wtolog('Pinging url ' + url.app_url + ' using image ' + url.img_url + '?r=' + rand);
    var img = $('<img class="pingimg"/>')
    img.attr('url', url.app_url);
    img.attr('status', 'down'); // default down, changed in onLoad
    img.load(function (e) {
	// So that we know it's been loaded
	wtolog('ping successful');
	jQuery(this).attr('status', 'up');
    });
    img.attr('src', url.img_url + '?r=' + rand);
    jQuery('#pingImages').append(img);

    // And call the callback in TIMEOUT seconds, to see whether it's been loaded
    setTimeout(function () {
	if (img.attr('status') == 'down') wtolog('URL is down');
	else wtolog('URL is up');
	callback(url, img.attr('status'));
    }, TIMEOUT*1000);
}

$('<div />') 	    

// moved out so we can stub it
function redirectTo(theurl) { window.location = theurl.app_url+"&option[platform]="+pirev+"-"+trrelease+"&option[loader]="+encodeURI(window.location.href); }

// Pad the log, so it appears below fixed elements
function setLogOffset() {
    var h = $('#fixed').height() + 10;
    $('#log').css('padding-top', h + 'px');
}

function loadapp() {
    // Make sure that we have a JSON object
    createJSONObj();

    // Check to make sure the hardware ID was written
    if (typeof hwid == 'undefined') {
			showError('nohwid');
			return false;
    }
    
    // make sure we have network connectivity
    confirmNetwork(hwid, function() {

	    // Set the log top padding, so it isn't subsumed by the beach ball
	    setLogOffset();
	
	    // Replace spans with the hwids
	    ids = document.getElementsByClassName('hwid');
	    for (var i = 0; i < ids.length; i++) { ids[i].innerHTML = hwid }
	    wtolog('Found Hardware ID: ' + hwid);
	    
	    getURLs(
				hwid,
				function (urls) {
				    chooseURL(urls, redirectTo);
				}
	    ); // getURLs
	    
	  });
    
    
}
