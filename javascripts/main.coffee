$(document).ready ->
  ref = new Firebase("https://browse-together.firebaseio.com");
  $('.login > div').on 'click', (e) ->
    console.log 'inside'
    $el = $ e.currentTarget
    auth = $el.attr('class')
    switch auth

      when 'google'
        ref.authWithOAuthRedirect 'google', (error, authData) ->
          sendResponse authData

      when 'github'
        ref.authWithOAuthRedirect 'github', (error, authData) ->
          sendResponse authData
