$(document).ready ->
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
