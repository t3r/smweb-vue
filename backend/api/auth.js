module.exports = function(passport) {
  const router = require('express').Router()

  router.get('/:provider', function(req,res,next) {
    const args = {
        twitter: {
          scope : [ 'profile', 'email' ]
        },
        google: {
          scope : [ 'profile', 'email' ]
        },
        facebook: {
          scope : 'email'
        },
        github: {
        }
    }[req.params.provider]
    if( !args ) return res.status(404).send('Unknown provider');

    passport.authenticate(req.params.provider, args)(req,res,next);
  })

  router.get('/:provider/callback', function(req,res,next) {
    passport.authenticate(req.params.provider, { session: true}, function(err,user,info){
      if( err ) {
        console.log("Passport.authenticate() error", err )
        return res.status(500).send('Sorry - there was an error when processing this request')
      }
      return res.redirect(user ? '/' : '/ups-nouser')
    })(req,res,next);
  })

  return router;
}
