ref = new Firebase("https://browse-together.firebaseio.com");
tab_location = "users"
setupTabs = (authData) ->
  ref.child("#{tab_location}/#{authData.uid}/tabs").onDisconnect().remove()
  chrome.tabs.query {}, (tabs) ->
    new_tab_data = {}
    for tab in tabs
      new_tab_data[tab.id] = {
        highlighted: tab.highlighted or false
        icon: tab.favIconUrl or ''
        title: tab.title or 'unkown'
        url: tab.url
      }
    timeout_id = null
    sendNewMessages = (messages) ->
      clearTimeout timeout_id if timeout_id
      timeout_id = setTimeout ( ->
        chrome.browserAction.setIcon {path:"icon2.png"}
        chrome.browserAction.setBadgeText {text: 'on'}
        chrome.runtime.sendMessage messages
      ), 200
    ref.child("#{tab_location}/#{authData.uid}/tabs").set new_tab_data, ->
      ref.child("users").on 'value', (user_doc) ->
        ref.child("#{tab_location}/#{authData.uid}/profile/friends").on 'value', (doc) ->
          doc_val = user_doc.val() or {}
          friends_val = doc.val() or {}
          friends_val[authData.uid] = true
          friends = Object.keys friends_val or []

          for friend in friends
            do (friend) ->
              ref.child("private_users/#{friend}").on 'value', ((doc) ->
                doc_val[friend] = doc.val()
                sendNewMessages doc_val
              ), (error) ->
                sendNewMessages doc_val

# attempt oauth
auth = localStorage.getItem 'auth'
chrome.browserAction.setBadgeText {text: 'off'}
if auth
  ref.authWithCustomToken auth, (err, authData) ->
    if err
      localStorage.removeItem 'auth'
    else
      tab_location = localStorage.getItem('tab_location') or 'users'
      ref.child("#{tab_location}/#{authData.uid}/profile").once 'value', (doc) ->
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
    ref.child("#{tab_location}/#{authData.uid}/profile").set user_blob, ->
      setupTabs authData

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  switch request.type

    when 'get-friends'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("#{tab_location}/#{authData.uid}/profile").once 'value', (doc) ->
        friends = Object.keys doc.child('friends').val() or {}
        console.log friends, 'zzz'
        return_friends = {}
        async.each friends, ((friend, next) ->
          ref.child("private_users/#{friend}").once 'value', ((doc) ->
            return_friends[friend] = true
            next()
          ), (error) ->
            return_friends[friend] = false
            next()
        ), ->
          sendResponse return_friends

    when 'get-local-user'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("#{tab_location}/#{authData.uid}/profile").once 'value', (doc) ->
        val = doc.val()
        val.uid = authData.uid
        sendResponse val or false

    when 'logout'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("#{tab_location}/#{authData.uid}/tabs").remove()
      ref.child("users").off 'value'
      chrome.browserAction.setIcon {path:"icon.png"}
      chrome.browserAction.setBadgeText {text: 'off'}
      localStorage.removeItem 'auth'
      ref.unauth()
      return sendResponse true

    when 'save-friends'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("#{tab_location}/#{authData.uid}/profile/friends").set request.list, ->
        ref.child("#{tab_location}/#{authData.uid}/profile").once 'value', (doc) ->
          val = doc.val()
          val.uid = authData.uid
          sendResponse val or false

    when 'update-settings'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("#{tab_location}/#{authData.uid}/profile").once 'value', (doc) ->
        current_doc = doc.val()
        {name, image, friends_only} = request.settings
        current_doc.name = name
        current_doc.image = image
        current_doc.private = friends_only
        tab_location = if friends_only then "private_users" else 'users'
        tab_original = if doc.child('private').val() then "private_users" else 'users'
        ref.child("#{tab_original}/#{authData.uid}/profile").set current_doc, ->
          current_doc.uid = authData.uid
          return sendResponse current_doc if tab_original is tab_location
          ref.child("#{tab_original}/#{authData.uid}").once 'value', (doc) ->
            user = doc.val()
            ref.child("#{tab_original}/#{authData.uid}").remove ->
              ref.child("#{tab_location}/#{authData.uid}").set user, ->
                localStorage.setItem('tab_location', tab_location)
                sendResponse current_doc

    when 'messages'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("users").once 'value', (doc_main) ->
        ref.child("#{tab_location}/#{authData.uid}").once 'value', (doc) ->
          cur_val = doc_main.val() or {}
          cur_val[authData.uid] = doc.val()
          friends = Object.keys doc.child('profile/friends').val() or {}
          async.each friends, ((friend, next) ->
            ref.child("private_users/#{friend}").once 'value', ((doc) ->
              cur_val[friend] or= doc?.val()
              next()
            ), (error) ->
              next()
          ), ->
            sendResponse cur_val

  return true


chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  return unless changeInfo.status is 'complete'
  authData = ref.getAuth()
  return unless authData
  ref.child("#{tab_location}/#{authData.uid}/tabs/#{tabId}").set {
    highlighted: tab.highlighted or false
    icon: tab.favIconUrl or ''
    title: tab.title or 'unkown'
    url: tab.url
  }, ->
    ref.child("#{tab_location}/#{authData.uid}/profile/last_modified").set Date.now()

chrome.tabs.onRemoved.addListener (tabId, changeInfo, tab) ->
  authData = ref.getAuth()
  return unless authData
  ref.child("#{tab_location}/#{authData.uid}/tabs/#{tabId}").remove ->
    ref.child("#{tab_location}/#{authData.uid}/profile/last_modified").set Date.now()

chrome.tabs.onReplaced.addListener (new_tab_id, remove_tab_id) ->
  authData = ref.getAuth()
  return unless authData
  ref.child("#{tab_location}/#{authData.uid}/tabs/#{remove_tab_id}").once 'value', (obj) ->
    ref.child("#{tab_location}/#{authData.uid}/tabs/#{new_tab_id}").set obj.val(), ->
      ref.child("#{tab_location}/#{authData.uid}/tabs/#{remove_tab_id}").remove ->
        ref.child("#{tab_location}/#{authData.uid}/profile/last_modified").set Date.now()

chrome.tabs.onActivated.addListener ({tabId, windowId}) ->
  authData = ref.getAuth()
  return unless authData
  chrome.tabs.getAllInWindow windowId, (arr) ->
    for tab in arr or []
      do (tab) ->
        ref.child("#{tab_location}/#{authData.uid}/tabs/#{tab.id}").once 'value', (obj) ->
          return if not obj?.val()
          ref.child("#{tab_location}/#{authData.uid}/tabs/#{tab.id}/highlighted").set tab.highlighted, ->
            ref.child("#{tab_location}/#{authData.uid}/profile/last_modified").set Date.now()
