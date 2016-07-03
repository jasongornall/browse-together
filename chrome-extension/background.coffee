
ref = new Firebase("https://browse-together.firebaseio.com");

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) ->
  ref.authWithCustomToken request.token

chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  return unless changeInfo.status is 'complete'
  ref.onAuth (authData) ->
    return unless authData
    ref.child("users/#{authData.uid}/#{tabId}").set {
      highlighted: tab.highlighted or false
      icon: tab.favIconUrl or ''
      title: tab.title or 'unkown'
      url: tab.url
    }, (e) ->
      console.log e, '123'

chrome.tabs.onRemoved.addListener (tabId, changeInfo, tab) ->
  ref.onAuth (authData) ->
    return unless authData
    ref.child("users/#{authData.uid}/#{tabId}").remove()

chrome.tabs.onReplaced.addListener (new_tab_id, remove_tab_id) ->
  ref.onAuth (authData) ->
    ref.child("users/#{authData.uid}/#{remove_tab_id}").once 'value', (obj) ->
      ref.child("users/#{authData.uid}/#{new_tab_id}").set obj.val()
      ref.child("users/#{authData.uid}/#{remove_tab_id}").remove()


chrome.tabs.onActivated.addListener ({tabId, windowId}) ->
  ref.onAuth (authData) ->
    return unless authData
    chrome.tabs.getAllInWindow windowId, (arr) ->
      for tab in arr or []
        do (tab) ->
          ref.child("users/#{authData.uid}/#{tab.id}").once 'value', (obj) ->
            return if not obj?.val()
            ref.child("users/#{authData.uid}/#{tab.id}/highlighted").set tab.highlighted
