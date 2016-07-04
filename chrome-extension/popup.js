// Generated by CoffeeScript 1.8.0
var timeout;

timeout = null;

document.addEventListener('DOMContentLoaded', function() {
  return chrome.runtime.sendMessage({
    type: 'get-local-user'
  }, function(data) {
    var logged_in, renderFriends, renderHeader, renderProfile, renderUsers;
    logged_in = Boolean(data);
    if (logged_in) {
      $('body').html(teacup.render(function() {
        div('.header', function() {
          img('.image');
          span(function() {
            return "Logged in as ";
          });
          return span('.name', function() {
            return '';
          });
        });
        div('.nav', function() {
          span('.users', function() {
            return 'users';
          });
          span('.profile', function() {
            return 'profile';
          });
          return span('.friends', function() {
            return 'friends';
          });
        });
        div('.users', function() {
          return div(function() {
            return 'Loading...';
          });
        });
        div('.profile', function() {
          return div(function() {
            return 'Loading...';
          });
        });
        return div('.friends', function() {
          return div(function() {
            return 'Loading...';
          });
        });
      }));
      renderHeader = function() {
        $('body > .header > .name').text(data.name);
        return $('body > .header > .image').attr('src', data.image);
      };
      renderFriends = function() {
        return chrome.runtime.sendMessage({
          type: 'get-friends'
        }, function(friends) {
          var $friends, apply_listener;
          $('body > .friends').html(teacup.render(function() {
            return div('.data', function() {
              div(function() {
                return "People I want to watch browse";
              });
              div('.friends', function() {
                var friend, is_mutual, _ref, _results;
                _ref = friends || {};
                _results = [];
                for (friend in _ref) {
                  is_mutual = _ref[friend];
                  _results.push(div('.friend', {
                    'data-uid': friend
                  }, function() {
                    span(function() {
                      return 'friend: ';
                    });
                    b(function() {
                      return "" + friend + " ";
                    });
                    span('.remove', function() {
                      return 'x';
                    });
                    if (!is_mutual) {
                      return span(function() {
                        return "* they can see you but you can't see them.. ask them t";
                      });
                    }
                  }));
                }
                return _results;
              });
              return div('.actions', function() {
                input('.friend', {
                  type: 'text'
                });
                span('.add-friend blue-button', function() {
                  return 'add friend';
                });
                return div(function() {
                  return span('.submit blue-button', function() {
                    return 'save';
                  });
                });
              });
            });
          }));
          $friends = $('body > .friends');
          apply_listener = function() {
            $friends = $('body > .friends');
            return $friends.find('.remove').off('click').on('click', function(e) {
              var $el, $friend;
              $el = $(e.currentTarget);
              $friend = $el.closest('.friend, .remove-friend');
              if ($friend.hasClass('new-friend')) {
                return $friend.remove();
              }
              return $el.closest('.friend, .remove-friend').toggleClass('friend remove-friend');
            });
          };
          apply_listener();
          $friends.find('.add-friend').on('click', function(e) {
            var friend;
            friend = $friends.find('input.friend').val();
            if (!friend) {
              return;
            }
            $friends.find('.friends').append(teacup.render(function() {
              return div('.friend new-friend', {
                'data-uid': friend
              }, function() {
                span(function() {
                  return 'friend: ';
                });
                b(function() {
                  return "" + friend + " ";
                });
                return span('.remove', function() {
                  return 'x';
                });
              });
            }));
            $friends.find('input.friend').val("");
            return apply_listener();
          });
          return $friends.find('.submit').on('click', function(e) {
            var $new_arr, friend, list, _i, _len;
            $new_arr = $friends.find('.friends > .friend');
            list = {};
            for (_i = 0, _len = $new_arr.length; _i < _len; _i++) {
              friend = $new_arr[_i];
              list[$(friend).data('uid')] = true;
            }
            return chrome.runtime.sendMessage({
              type: 'save-friends',
              list: list
            }, function(new_data) {
              if (!new_data) {
                return;
              }
              data = new_data;
              renderFriends();
              return renderUsers();
            });
          });
        });
      };
      renderProfile = function() {
        $('body > .profile').html(teacup.render(function() {
          div('.data', function() {
            div(function() {
              span(function() {
                return "my friend code: ";
              });
              return b(function() {
                return data.uid;
              });
            });
            div(function() {
              span(function() {
                return 'name: ';
              });
              return input('.name', {
                type: 'text',
                value: data.name
              });
            });
            div(function() {
              span(function() {
                return 'image: ';
              });
              return input('.image', {
                type: 'text',
                value: data.image
              });
            });
            return div(function() {
              input('.private', {
                type: 'checkbox',
                checked: data["private"] || false
              });
              return span(function() {
                return 'only friends can see me browse';
              });
            });
          });
          return div('.actions', function() {
            span('.submit blue-button', function() {
              return 'submit';
            });
            return span('.logout .blue-button', function() {
              return 'logout';
            });
          });
        }));
        $('.logout').on('click', function(e) {
          return chrome.runtime.sendMessage({
            type: 'logout'
          }, function(data) {
            if (data) {
              return location.reload();
            }
          });
        });
        return $('body > .profile .submit').on('click', function(e) {
          return chrome.runtime.sendMessage({
            type: 'update-settings',
            settings: {
              name: $('body > .profile input.name').val(),
              image: $('body > .profile input.image').val(),
              friends_only: Boolean($('body > .profile input.private:checked').length)
            }
          }, function(new_data) {
            if (!new_data) {
              return;
            }
            data = new_data;
            debugger;
            renderHeader();
            renderUsers();
            return renderProfile();
          });
        });
      };
      renderUsers = function() {
        var processMessages;
        processMessages = function(users) {
          clearTimeout(timeout);
          return timeout = setTimeout((function() {
            $('body > .users').html(teacup.render(function() {
              var key, profile, tabs, val, _results;
              _results = [];
              for (key in users) {
                val = users[key];
                profile = val.profile, tabs = val.tabs;
                if (!Object.keys(tabs || {}).length) {
                  continue;
                }
                _results.push(div('.user', {
                  'data-user': key
                }, function() {
                  div('.header', function() {
                    img('.image', {
                      src: profile.image
                    });
                    span('.name', function() {
                      return profile.name;
                    });
                    return time('.time', {
                      'datetime': new Date(profile.last_modified).toISOString()
                    }, function() {
                      return '';
                    });
                  });
                  return div('.tabs', function() {
                    var highlighted, key_t, val_t, _i, _len, _ref, _results1;
                    _ref = [true, false];
                    _results1 = [];
                    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                      highlighted = _ref[_i];
                      _results1.push((function() {
                        var _results2;
                        _results2 = [];
                        for (key_t in tabs) {
                          val_t = tabs[key_t];
                          if (val_t.highlighted !== highlighted) {
                            continue;
                          }
                          _results2.push(div('.tab', {
                            'data-highlighted': val_t.highlighted
                          }, function() {
                            val_t.icon || (val_t.icon = 'transparent.ico');
                            img('.image', {
                              src: val_t.icon
                            });
                            return span('.content', function() {
                              div('.title', function() {
                                return val_t.title;
                              });
                              return a('.link', {
                                target: '_blank',
                                href: val_t.url
                              }, function() {
                                return val_t.url;
                              });
                            });
                          }));
                        }
                        return _results2;
                      })());
                    }
                    return _results1;
                  });
                }));
              }
              return _results;
            }));
            return $('time.time').timeago();
          }), 1000);
        };
        chrome.runtime.sendMessage({
          type: 'messages'
        }, function(messages) {
          return processMessages(messages);
        });
        return chrome.runtime.onMessage.addListener(function(messages, sender, sendResponse) {
          return processMessages(messages);
        });
      };
      $('body > .nav > span').on('click', function(e) {
        var $el;
        $el = $(e.currentTarget);
        return $el.closest('body').attr('data-state', $el.attr('class'));
      });
      renderHeader();
      renderFriends();
      renderProfile();
      return renderUsers();
    } else {
      $('body').html(teacup.render(function() {
        return div('.login blue-button', function() {
          return 'Click here to login and get started!';
        });
      }));
      return $('.login').on('click', function(e) {
        return window.open('https://jasongornall.github.io/browse-together/', '_blank');
      });
    }
  });
});
