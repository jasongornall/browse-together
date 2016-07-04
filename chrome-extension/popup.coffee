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

        div '.nav', ->
          span '.users', -> 'users'
          span '.profile', -> 'profile'
          span '.friends', -> 'friends'
        div '.users', ->
          div -> 'Loading...'
        div '.profile', ->
          div -> 'Loading...'
        div '.friends', ->
          div -> 'Loading...'
      renderHeader = ->
        $('body > .header > .name').text data.name
        $('body > .header > .image').attr 'src', data.image
      renderFriends = ->

        chrome.runtime.sendMessage {type: 'get-friends'}, (friends) ->
          $('body > .friends').html teacup.render ->
            div '.data', ->
              div ->
                "People I want to watch browse"
              div '.friends', ->
                for friend, is_mutual of friends or { }
                  div '.friend', 'data-uid': friend, ->
                    span -> 'friend: '
                    b -> "#{friend} "
                    span '.remove', -> 'x'
                    if not is_mutual
                      span -> "* they can see you but you can't see them.. ask them t"

              div '.actions', ->
                input '.friend', type: 'text'
                span '.add-friend blue-button', -> 'add friend'
                div ->
                  span '.submit blue-button', -> 'save'


          $friends = $('body > .friends')
          apply_listener = ->
            $friends = $('body > .friends')
            $friends.find('.remove').off('click').on 'click', (e) ->
              $el = $ e.currentTarget
              $friend = $el.closest('.friend, .remove-friend')
              return $friend.remove() if $friend.hasClass 'new-friend'
              $el.closest('.friend, .remove-friend').toggleClass 'friend remove-friend'

          apply_listener()
          $friends.find('.add-friend').on 'click', (e) ->
            friend = $friends.find('input.friend').val()
            return unless friend
            $friends.find('.friends').append teacup.render ->
              div '.friend new-friend', 'data-uid': friend, ->
                span -> 'friend: '
                b -> "#{friend} "
                span '.remove', -> 'x'
            $friends.find('input.friend').val("")
            apply_listener()

          $friends.find('.submit').on 'click', (e) ->
            $new_arr = $friends.find('.friends > .friend')
            list = {}
            for friend in $new_arr
              list[$(friend).data('uid')] = true
            chrome.runtime.sendMessage {
              type: 'save-friends'
              list: list
            }, (new_data) ->
              return unless new_data
              data = new_data
              renderFriends()
              renderUsers()
      renderProfile = ->
        $('body > .profile').html teacup.render ->
          div '.data', ->
            div ->
              span -> "my friend code: "
              b -> data.uid
            div ->
              span -> 'name: '
              input '.name', type: 'text', value: data.name
            div ->
              span -> 'image: '
              input '.image', type: 'text', value: data.image
            div ->
              input '.private', type: 'checkbox', checked: data.private or false
              span -> 'only friends can see me browse'

          div '.actions', ->
            span '.submit blue-button', -> 'submit'
            span '.logout .blue-button', -> 'logout'

        $('.logout').on 'click', (e) ->
          chrome.runtime.sendMessage {
            type: 'logout'
          }, (data) ->
            location.reload() if data
        $('body > .profile .submit').on 'click', (e) ->
          chrome.runtime.sendMessage {
            type: 'update-settings'
            settings: {
              name: $('body > .profile input.name').val()
              image: $('body > .profile input.image').val()
              friends_only: Boolean $('body > .profile input.private:checked').length
            }
          }, (new_data) ->
            return unless new_data
            data = new_data
            debugger;
            renderHeader()
            renderUsers()
            renderProfile()

      renderUsers = ->
        processMessages = (users) ->
          clearTimeout timeout
          timeout = setTimeout ( ->
            $('body > .users').html teacup.render ->
              for key, val of users
                {profile, tabs} = val
                continue unless Object.keys(tabs or {}).length
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

      $('body > .nav > span').on 'click', (e) ->
        $el = $ e.currentTarget
        $el.closest('body').attr 'data-state', $el.attr('class')

      renderHeader()
      renderFriends()
      renderProfile()
      renderUsers()

    else
      $('body').html teacup.render ->
        div '.login blue-button', ->
          'Click here to login and get started!'

      # handle login
      $('.login').on 'click', (e) ->
        window.open 'https://jasongornall.github.io/browse-together/', '_blank'

