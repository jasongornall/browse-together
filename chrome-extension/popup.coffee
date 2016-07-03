
document.addEventListener 'DOMContentLoaded', ->

  # get status of user
  chrome.runtime.sendMessage {
    type: 'auth-status'
  }, (user_info) ->
    console.log user_info
    $('body').addClass 'login'

  # handle login
  $('.login > div').on 'click', (e) ->
    console.log 'inside'
    $el = $ e.currentTarget

    auth = $el.attr('class')
    chrome.runtime.sendMessage {
      type: "#{auth}-oauth"
    }, (user_info) ->
      console.log user_info
