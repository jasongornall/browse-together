timeout = null
document.addEventListener 'DOMContentLoaded', ->
  chrome.runtime.sendMessage {
    type: 'get-local-user'
  }, (data) ->
    logged_in = Boolean data

    if logged_in
      $('body').html teacup.render ->
        div '.header', ->
          img '.image'
          span -> "Logged in as "
          span '.name', -> ''
          span '.logout', -> 'logout'
        div '.users', ->
          div -> 'Loading...'

      $('body .header > .name').text data.name
      $('body .header > .image').attr 'src', data.image

      $('.logout').on 'click', (e) ->
        chrome.runtime.sendMessage {
          type: 'logout'
        }, (data) ->
          location.reload()

      processMessages = (users) ->
        console.log users, '123'
        clearTimeout timeout
        timeout = setTimeout ( ->
          for key, val of users
            {profile, tabs } = val
            $('.users').html  teacup.render ->
              div '.user', 'data-user': key, ->
                div '.header', ->
                  img '.image', src: profile.image
                  span '.name', -> profile.name
                div '.tabs', ->
                  for key_t, val_t of tabs
                    div '.tab', 'data-highlighted': val_t.highlighted, ->
                      img '.image', src: val_t.icon
                      div '.title', -> val_t.title
                      div '.link', -> val_t.url
        ), 1000


      chrome.runtime.sendMessage {type: 'messages'}, (messages) ->
        processMessages messages
      chrome.runtime.onMessage.addListener (messages, sender, sendResponse) ->
        processMessages messages

    else
      $('body').html teacup.render ->
        div '.login', ->
          'Click here to login and get started!'

      # handle login
      $('.login').on 'click', (e) ->
        debugger;
        window.open 'https://jasongornall.github.io/browse-together/', '_blank'

