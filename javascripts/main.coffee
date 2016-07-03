$(document).ready ->
  ref = new Firebase("https://browse-together.firebaseio.com");
  sendResponse = (authData)->
    editorExtensionId = "icannhlkkebffkcfgonfhengcgibfpbb";
    chrome.runtime.sendMessage editorExtensionId, authData
    window.close()

  $('.login > div').on 'click', (e) ->
    console.log 'inside'
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
