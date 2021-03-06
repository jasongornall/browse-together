timeout = null
document.addEventListener 'DOMContentLoaded', ->
  state = localStorage.getItem('body-state') or 'private-users'
  $('body').attr 'data-state', state
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
          span '.users', -> 'public users'
          span '.private-users', -> 'my friends'
          span '.profile', -> 'profile'
          span '.friends', -> 'friends add/remove'
        div '.users', ->
          div -> 'Loading...'
        div '.private-users', ->
          div -> 'loading...'
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
                for friend, name of friends
                  div '.friend', 'data-uid': friend, ->
                    span -> 'friend: '
                    b -> "#{friend} "
                    span ->"(#{name})" if name
                    span '.remove', -> 'x'

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
            renderHeader()
            renderUsers()
            renderProfile()

      renderUsers = ->
        processMessages = (users, location="users") ->
          user_sort = Object.keys users or {}
          user_sort.sort (a, b) ->
            return -1 if a is data.uid
            return 1 if b is data.uid
            return a > b

          $users = $("body > .#{location}")
          $users.html teacup.render ->
            for key in user_sort
              val = users[key]
              {profile, tabs} = val or {}
              continue unless profile
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
                      continue unless val_t.title
                      div '.tab', 'data-highlighted': val_t.highlighted, ->
                        val_t.icon or= 'transparent.ico'
                        if data.uid is key
                          span '.remove', 'data-tab': key_t, -> 'x '
                        img '.image', src: val_t.icon
                        span '.content', ->
                          div '.title', -> val_t.title
                          a '.link', target:'_blank', href:val_t.url, -> val_t.url
          $users.find('time.time').timeago()
          $users.find('.remove').on 'click', (e) ->
            $el = $ e.currentTarget
            chrome.tabs.remove $el.data 'tab'

        async.waterfall [
          (finish) =>
            chrome.runtime.sendMessage {type: 'messages'}, (messages) ->
              processMessages messages, 'users'
              finish()

          (finish) =>
            chrome.runtime.sendMessage {type: 'friends-messages'}, (messages) ->
              processMessages messages, 'private-users'
              finish()

          (finish) =>
            chrome.runtime.onMessage.addListener ({type, data}, sender, sendResponse) ->
              processMessages data, type
        ]

      $('body > .nav > span').on 'click', (e) ->
        $el = $ e.currentTarget
        $el.closest('body').attr 'data-state', $el.attr('class')
        localStorage.setItem 'body-state', $el.attr('class')

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

