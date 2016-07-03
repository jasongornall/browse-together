
ref = new Firebase("https://browse-together.firebaseio.com");
chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  switch request.type

    when 'auth-status'
      ref.onAuth (authData) ->
        main_auth_data = authData
        sendResponse authData

    when 'google-oauth'
      ref.authWithOAuthRedirect 'google', (error, authData) ->
        sendResponse authData

    when 'github-oauth'
      ref.authWithOAuthRedirect 'github', (error, authData) ->
        sendResponse authData

chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  console.log tabId, changeInfo, tab
  return unless changeInfo.status is 'complete'
  ref.onAuth (authData) ->
    return unless authData
    ref.child("users.#{authData.uid}.#{tabId}").set {
      highlighted: tab.highlighted
      icon: tab.favIconUrl
      title: tab.title
      url: tab.url
    }, (e) ->
      console.log e, '123'

chrome.tabs.onRemoved.addListener (tabId, changeInfo, tab) ->
  ref.onAuth (authData) ->
    return unless authData
    ref.child("users.#{authData.uid}.#{tabId}").remove()

chrome.tabs.onActivated.addListener ({tabId, windowId}) ->
  ref.onAuth (authData) ->
    return unless authData
    chrome.tabs.getAllInWindow windowId, (arr) ->
      ref.onAuth (authData) ->
        for tab in arr
          h = tab.highlighted
          ref.child("users.#{authData.uid}.#{tab.id}.highlighted").set h, (e) ->
            console.log e, '123'
