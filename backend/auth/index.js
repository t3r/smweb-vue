const router = require('express').Router()

module.exports = function(passport) {

  router.get('/github', passport.authenticate('github', { scope: [] }));
    
  router.get('/github/callback', 
    passport.authenticate('github', { failureRedirect: '/#/login' }),
    function(req,res,next) {
      if( req.user.id ) {
        const b = Buffer.from(JSON.stringify(req.user)).toString('base64');
        return res.redirect(`/#/login/callback?code=${b}`);
      } else {
        return res.redirect('/');
      }
    });
  

  router.get('/me', function(req,res) {
    res.json(req.user);
  });

  router.get('/logout', function(req,res,next) {
    req.logout(function(err) {
      if (err) { return next(err); }
      res.redirect('/#/login');
    });
  });

  return router;
}

