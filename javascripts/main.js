// Generated by CoffeeScript 1.8.0
$(document).ready(function() {
  var ref;
  ref = new Firebase("https://browse-together.firebaseio.com");
  return $('.login > div').on('click', function(e) {
    var $el, auth;
    console.log('inside');
    $el = $(e.currentTarget);
    auth = $el.attr('class');
    switch (auth) {
      case 'google':
        return ref.authWithOAuthPopup('google', function(error, authData) {
          return sendResponse(authData);
        });
      case 'github':
        return ref.authWithOAuthPopup('github', function(error, authData) {
          return sendResponse(authData);
        });
    }
  });
});
