ref = new Firebase("https://browse-together.firebaseio.com");
tab_location = "nope"
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
    sendNewMessages = (messages) ->
      chrome.browserAction.setIcon {path:"icon2.png"}
      chrome.browserAction.setBadgeText {text: 'on'}
      chrome.runtime.sendMessage messages

    ref.child("#{tab_location}/#{authData.uid}/tabs").set new_tab_data, ->
      ref.child("users").on 'value', (user_doc) ->
        sendNewMessages {type: 'users', data: user_doc.val()}

      doc_val = {}
      ref.child("#{tab_location}/#{authData.uid}/profile/friends").on 'value', (doc) ->
        for friend, val of doc_val
          ref.child("users/#{friend}").off 'value'
          ref.child("private_users/#{friend}").off 'value'
        doc_val = {}
        friends_val = doc.val() or {}
        friends_val[authData.uid] = true
        friends = Object.keys friends_val or []

        for friend in friends
          do (friend) ->
            ref.child("users/#{friend}").on 'value', (doc) ->
              doc_val[friend] = doc.val()
              if Boolean doc_val[friend]
                sendNewMessages {type: 'private-users', data: doc_val}
              else
                ref.child("private_users/#{friend}").on 'value', (doc) ->
                  doc_val[friend] = doc.val()
                  sendNewMessages {type: 'private-users', data: doc_val}



# attempt oauth
auth = localStorage.getItem 'auth'
chrome.browserAction.setBadgeText {text: 'off'}
if auth
  ref.authWithCustomToken auth, (err, authData) ->
    if err
      localStorage.removeItem 'auth'
    else
      tab_location = localStorage.getItem('tab_location') or 'users'
      ref.child("private_users/#{authData.uid}/profile").once 'value', (doc) ->
        if doc.val()
          tab_location = "private_users"
          setupTabs authData
        else
          tab_location = "users"
          ref.child("users/#{authData.uid}/profile").once 'value', (doc) ->
            setupTabs authData

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) ->
  localStorage.setItem 'auth', request.token
  ref.authWithCustomToken request.token, (err, authData) ->
    ref.child("#{tab_location}/#{authData.uid}/profile").once 'value', (og_doc) ->
      return unless authData
      user_blob = {}
      switch request.provider

        when 'google'
          user_blob.name = request.google.displayName
          user_blob.image = request.google.profileImageURL
          user_blob.last_modified = Date.now()
          user_blob.private = og_doc.child('private').val() or false
          user_blob.friends = og_doc.child('friends').val() or {}

        when 'github'
          user_blob.name = request.github.displayName
          user_blob.image = request.github.profileImageURL
          user_blob.last_modified = Date.now()
          user_blob.private = og_doc.child('private').val() or false
          user_blob.friends = og_doc.child('friends').val() or {}
      ref.child("#{tab_location}/#{authData.uid}/profile").set user_blob, ->
        setupTabs authData

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  switch request.type

    when 'get-friends'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("#{tab_location}/#{authData.uid}/profile").once 'value', (doc) ->
        friends = Object.keys doc.child('friends').val() or {}
        return_friends = {}
        async.each friends, ((friend, next) ->
          ref.child("private_users/#{friend}").once 'value', ((doc) ->
            return_friends[friend] = doc.child('profile/name').val()
            next()
          ), (error) ->
            ref.child("users/#{friend}").once 'value', (doc) ->
              return_friends[friend] = doc.child('profile/name').val()
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
      ref.child("#{tab_location}/#{authData.uid}").once 'value', (doc) ->
        user_val = doc.val() or {}

        {name, image, friends_only} = request.settings
        user_val.profile ?= {}
        user_val.profile.name = name
        user_val.profile.image = image
        user_val.profile.private = friends_only
        tab_location = if friends_only then "private_users" else 'users'
        tab_original = if doc.child('profile/private').val() then "private_users" else 'users'
        ref.child("#{tab_original}/#{authData.uid}/profile").set user_val.profile, ->
          user_val.profile.uid = authData.uid
          if tab_original is tab_location
            user_val.profile.uid = authData.uid
            return sendResponse user_val.profile
          ref.child("#{tab_original}/#{authData.uid}").remove ->
            ref.child("#{tab_location}/#{authData.uid}").set user_val, ->
              user_val.profile.uid = authData.uid
              sendResponse user_val.profile

    when 'messages'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("users").once 'value', (doc_main) ->
        sendResponse doc_main.val()

    when 'friends-messages'
      authData = ref.getAuth()
      return sendResponse false unless authData
      ref.child("#{tab_location}/#{authData.uid}").once 'value', (doc) ->
        cur_val = {}
        cur_val[authData.uid] = doc.val()
        friends = Object.keys doc.child('profile/friends').val() or {}
        async.each friends, ((friend, next) ->
          ref.child("private_users/#{friend}").once 'value', ((doc) ->
            cur_val[friend] or= doc?.val()
            next()
          ), (error) ->
            ref.child("users/#{friend}").once 'value', (doc) ->
              cur_val[friend] or= doc?.val()
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
    tab_data = obj.val()
    ref.child("#{tab_location}/#{authData.uid}/tabs/#{remove_tab_id}").remove ->
      ref.child("#{tab_location}/#{authData.uid}/tabs/#{new_tab_id}").set tab_data, ->
        ref.child("#{tab_location}/#{authData.uid}/profile/last_modified").set Date.now()

chrome.tabs.onActivated.addListener ({tabId, windowId}) ->
  authData = ref.getAuth()
  return unless authData
  chrome.tabs.getAllInWindow windowId, (arr) ->
    ref.child("#{tab_location}/#{authData.uid}").once 'value', (user_doc) ->
      user = user_doc.val()
      for tab in arr or []
        user.tabs[tab.id] ?= {}
        user.tabs[tab.id].highlighted = tab.highlighted
        user.profile.last_modifed = Date.now()
      ref.child("#{tab_location}/#{authData.uid}").set user
