$(document).ready ->
  ref = new Firebase("https://browse-together.firebaseio.com");
  sendResponse = (authData)->
    editorExtensionId = "abcdefghijklmnoabcdefhijklmnoabc";
    chrome.runtime.sendMessage editorExtensionId, authData

  $('.login > div').on 'click', (e) ->
    console.log 'inside'
    $el = $ e.currentTarget
    auth = $el.attr('class')
    switch auth

      when 'google'
        ref.authWithOAuthPopup 'google', (error, authData) ->
          sendResponse authData

      when 'github'
        ref.authWithOAuthPopup 'github', (error, authData) ->
          sendResponse authData
