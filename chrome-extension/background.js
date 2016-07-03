// Generated by CoffeeScript 1.8.0
var ref;

ref = new Firebase("https://browse-together.firebaseio.com");

chrome.runtime.onMessageExternal.addListener(function(request, sender, sendResponse) {
  return ref.authWithCustomToken(request.token, function(err, authData) {
    var user_blob;
    user_blob = {};
    switch (request.provider) {
      case 'google':
        user_blob.name = request.google.displayName;
        user_blob.image = request.google.profileImageURL;
        break;
      case 'github':
        user_blob.name = request.github.displayName;
        user_blob.image = request.github.profileImageURL;
    }
    debugger;
    ref.child("users/" + authData.uid + "/profile").set(user_blob);
    return ref.child("users").on('value', function(doc) {
      console.log('inside');
      return chrome.runtime.sendMessage(doc.val());
    });
  });
});

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  switch (request.type) {
    case 'get-local-user':
      ref.onAuth(function(authData) {
        if (!authData) {
          return sendResponse(false);
        }
        return ref.child("users/" + authData.uid + "/profile").once('value', function(doc) {
          return sendResponse(doc.val() || false);
        });
      });
      break;
    case 'logout':
      ref.unauth();
      break;
    case 'messages':
      ref.onAuth(function(authData) {
        if (!authData) {
          return sendResponse(false);
        }
        return ref.child("users").once('value', function(doc) {
          return sendResponse(doc.val() || {});
        });
      });
  }
  return true;
});

chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
  if (changeInfo.status !== 'complete') {
    return;
  }
  return ref.onAuth(function(authData) {
    if (!authData) {
      return;
    }
    return ref.child("users/" + authData.uid + "/tabs/" + tabId).set({
      highlighted: tab.highlighted || false,
      icon: tab.favIconUrl || '',
      title: tab.title || 'unkown',
      url: tab.url
    });
  });
});

chrome.tabs.onRemoved.addListener(function(tabId, changeInfo, tab) {
  return ref.onAuth(function(authData) {
    if (!authData) {
      return;
    }
    return ref.child("users/" + authData.uid + "/tabs/" + tabId).remove();
  });
});

chrome.tabs.onReplaced.addListener(function(new_tab_id, remove_tab_id) {
  return ref.onAuth(function(authData) {
    if (!authData) {
      return;
    }
    return ref.child("users/" + authData.uid + "/tabs/" + remove_tab_id).once('value', function(obj) {
      ref.child("users/" + authData.uid + "/tabs/" + new_tab_id).set(obj.val());
      return ref.child("users/" + authData.uid + "/tabs/" + remove_tab_id).remove();
    });
  });
});

chrome.tabs.onActivated.addListener(function(_arg) {
  var tabId, windowId;
  tabId = _arg.tabId, windowId = _arg.windowId;
  return ref.onAuth(function(authData) {
    if (!authData) {
      return;
    }
    return chrome.tabs.getAllInWindow(windowId, function(arr) {
      var tab, _i, _len, _ref, _results;
      _ref = arr || [];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        tab = _ref[_i];
        _results.push((function(tab) {
          return ref.child("users/" + authData.uid + "/tabs/" + tab.id).once('value', function(obj) {
            if (!(obj != null ? obj.val() : void 0)) {
              return;
            }
            return ref.child("users/" + authData.uid + "/tabs/" + tab.id + "/highlighted").set(tab.highlighted);
          });
        })(tab));
      }
      return _results;
    });
  });
});
