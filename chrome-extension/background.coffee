ref = new Firebase("https://browse-together.firebaseio.com");

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) ->
  ref.authWithCustomToken request.token, (err, authData) ->
    user_blob = {}
    switch request.provider

      when 'google'
        user_blob.name = request.google.displayName
        user_blob.image = request.google.profileImageURL

      when 'github'
        user_blob.name = request.github.displayName
        user_blob.image = request.github.profileImageURL

    debugger;
    ref.child("users/#{authData.uid}/profile").set user_blob

    ref.child("users").on 'value', (doc) ->
      console.log 'inside'
      chrome.runtime.sendMessage doc.val()

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  switch request.type

    when 'get-local-user'
      ref.onAuth (authData) ->
        return sendResponse false unless authData
        ref.child("users/#{authData.uid}/profile").once 'value', (doc) ->
          sendResponse doc.val() or false

    when 'logout'
      ref.unauth()

    when 'messages'
      ref.onAuth (authData) ->
        return sendResponse false unless authData
        ref.child("users").once 'value', (doc) ->
          sendResponse doc.val() or {}


  return true


chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  return unless changeInfo.status is 'complete'
  ref.onAuth (authData) ->
    return unless authData
    ref.child("users/#{authData.uid}/tabs/#{tabId}").set {
      highlighted: tab.highlighted or false
      icon: tab.favIconUrl or ''
      title: tab.title or 'unkown'
      url: tab.url
    }

chrome.tabs.onRemoved.addListener (tabId, changeInfo, tab) ->
  ref.onAuth (authData) ->
    return unless authData
    ref.child("users/#{authData.uid}/tabs/#{tabId}").remove()

chrome.tabs.onReplaced.addListener (new_tab_id, remove_tab_id) ->
  ref.onAuth (authData) ->
    return unless authData
    ref.child("users/#{authData.uid}/tabs/#{remove_tab_id}").once 'value', (obj) ->
      ref.child("users/#{authData.uid}/tabs/#{new_tab_id}").set obj.val()
      ref.child("users/#{authData.uid}/tabs/#{remove_tab_id}").remove()

chrome.tabs.onActivated.addListener ({tabId, windowId}) ->
  ref.onAuth (authData) ->
    return unless authData
    chrome.tabs.getAllInWindow windowId, (arr) ->
      for tab in arr or []
        do (tab) ->
          ref.child("users/#{authData.uid}/tabs/#{tab.id}").once 'value', (obj) ->
            return if not obj?.val()
            ref.child("users/#{authData.uid}/tabs/#{tab.id}/highlighted").set tab.highlighted
