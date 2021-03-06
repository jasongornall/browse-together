$(document).ready ->
  ref = new Firebase("https://browse-together.firebaseio.com");
  ref.unauth()
  sendResponse = (authData)->
    editorExtensionId = "aojjpgcfbifipkmelibaclhgggacpcim";
    chrome.runtime.sendMessage editorExtensionId, authData
    window.close()

  $('.login > div').on 'click', (e) ->
    $el = $ e.currentTarget
    auth = $el.attr('class')
    switch auth

      when 'google'
        ref.authWithOAuthPopup 'google', ((error, authData) ->
          sendResponse authData
        ), {
          scope: 'profile'
        }

      when 'github'
        ref.authWithOAuthPopup 'github', (error, authData) ->
          sendResponse authData

      when 'facebook'
        ref.authWithOAuthPopup 'facebook', (error, authData) ->
          sendResponse authData
