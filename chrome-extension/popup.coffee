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
        clearTimeout timeout
        timeout = setTimeout ( ->
          $('.users').html teacup.render ->
            for key, val of users
              {profile, tabs } = val
              div '.user', 'data-user': key, ->
                div '.header', ->
                  img '.image', src: profile.image
                  span '.name', -> profile.name
                  time '.time', 'datetime': new Date(profile.last_modified).toISOString(), -> ''
                div '.tabs', ->
                  for highlighted in [true, false]
                    for key_t, val_t of tabs
                      continue unless val_t.highlighted is highlighted
                      div '.tab', 'data-highlighted': val_t.highlighted, ->
                        val_t.icon or= 'transparent.ico'
                        img '.image', src: val_t.icon
                        span '.content', ->
                          div '.title', -> val_t.title
                          a '.link', target:'_blank', href:val_t.url, -> val_t.url
          $('time.time').timeago()
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
        window.open 'https://jasongornall.github.io/browse-together/', '_blank'

