ref = new Firebase("https://browse-together.firebaseio.com");

setupTabs = (authData) ->
  ref.child("users/#{authData.uid}/tabs").onDisconnect().remove()
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
        chrome.browserAction.setIcon {path:"icon2.png"}
        chrome.browserAction.setBadgeText {text: 'on'}
        chrome.runtime.sendMessage doc.val() or {}

# attempt oauth
auth = localStorage.getItem 'auth'
chrome.browserAction.setBadgeText {text: 'off'}
if auth
  ref.authWithCustomToken auth, (err, authData) ->
    if err
      localStorage.removeItem 'auth'
    else
      setupTabs authData

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) ->
  localStorage.setItem 'auth', request.token
  ref.authWithCustomToken request.token, (err, authData) ->
    return unless authData
    user_blob = {}
    switch request.provider

      when 'google'
        user_blob.name = request.google.displayName
        user_blob.image = request.google.profileImageURL
        user_blob.last_modified = Date.now()

      when 'github'
        user_blob.name = request.github.displayName
        user_blob.image = request.github.profileImageURL
        user_blob.last_modified = Date.now()
    ref.child("users/#{authData.uid}/profile").set user_blob
    setupTabs authData

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  switch request.type

    when 'get-local-user'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("users/#{authData.uid}/profile").once 'value', (doc) ->
        sendResponse doc.val() or false

    when 'logout'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("users/#{authData.uid}").remove()
      ref.child("users").off 'value'
      chrome.browserAction.setIcon {path:"icon.png"}
      chrome.browserAction.setBadgeText {text: 'off'}
      localStorage.removeItem 'auth'
      ref.unauth()

    when 'messages'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("users").once 'value', (doc) ->
        sendResponse doc.val() or {}

  return true


chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  return unless changeInfo.status is 'complete'
  authData = ref.getAuth()
  return unless authData
  ref.child("users/#{authData.uid}/tabs/#{tabId}").set {
    highlighted: tab.highlighted or false
    icon: tab.favIconUrl or ''
    title: tab.title or 'unkown'
    url: tab.url
  }
  ref.child("users/#{authData.uid}/profile/last_modified").set Date.now()

chrome.tabs.onRemoved.addListener (tabId, changeInfo, tab) ->
  authData = ref.getAuth()
  return unless authData
  ref.child("users/#{authData.uid}/tabs/#{tabId}").remove()
  ref.child("users/#{authData.uid}/profile/last_modified").set Date.now()

chrome.tabs.onReplaced.addListener (new_tab_id, remove_tab_id) ->
  authData = ref.getAuth()
  return unless authData
  ref.child("users/#{authData.uid}/tabs/#{remove_tab_id}").once 'value', (obj) ->
    ref.child("users/#{authData.uid}/tabs/#{new_tab_id}").set obj.val()
    ref.child("users/#{authData.uid}/tabs/#{remove_tab_id}").remove()
    ref.child("users/#{authData.uid}/profile/last_modified").set Date.now()

chrome.tabs.onActivated.addListener ({tabId, windowId}) ->
  authData = ref.getAuth()
  return unless authData
  chrome.tabs.getAllInWindow windowId, (arr) ->
    for tab in arr or []
      do (tab) ->
        ref.child("users/#{authData.uid}/tabs/#{tab.id}").once 'value', (obj) ->
          return if not obj?.val()
          ref.child("users/#{authData.uid}/tabs/#{tab.id}/highlighted").set tab.highlighted
          ref.child("users/#{authData.uid}/profile/last_modified").set Date.now()
