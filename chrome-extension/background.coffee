ref = new Firebase("https://browse-together.firebaseio.com");

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) ->
  ref = new Firebase("https://browse-together.firebaseio.com");

  ref.authWithCustomToken request.token, (err, authData) ->
    debugger;
    user_blob = {}
    switch request.provider

      when 'google'
        user_blob.name = request.google.displayName
        user_blob.image = request.google.profileImageURL

      when 'github'
        user_blob.name = request.github.displayName
        user_blob.image = request.github.profileImageURL

    ref.child("users/#{authData.uid}/profile").set user_blob
    ref.child("users/#{authData.uid}").onDisconnect().remove()
    chrome.tabs.query {}, (tabs) ->
      new_tab_data = {}
      for tab in tabs
        new_tab_data[tab.id] = {
          highlighted: tab.highlighted or false
          icon: tab.favIconUrl or ''
          title: tab.title or 'unkown'
          url: tab.url
        }
      ref.child("users/#{authData.uid}/tabs").set new_tab_data, ->
        ref.child("users").on 'value', (doc) ->
          chrome.runtime.sendMessage doc.val() or {}

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  switch request.type

    when 'get-local-user'
      ref.onAuth (authData) ->
        return sendResponse false unless authData
        ref.child("users/#{authData.uid}/profile").once 'value', (doc) ->
          sendResponse doc.val() or false

    when 'logout'
      ref.onAuth (authData) ->
        return sendResponse false unless authData
        ref.child("users/#{authData.uid}").remove()
        ref.child("users").off 'value'
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
