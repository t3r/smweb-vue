process.env.node_env = process.env.node_env || 'development';

const express = require('express');
const logger = require('morgan');
const passport = require('passport');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const pgSession = require('connect-pg-simple')(session);

const { pgPool } = require('./db.js');

const app = express();

require('./auth/passport.js')(passport);

app.use(logger(process.env.node_env  === 'development' ? 'dev' : 'combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());

app.use(bodyParser.json({
  strict : true,
  limit:'5mb',
}));

app.use(session({
  store: new pgSession({
    pool : pgPool,
    tableName : 'user_sessions',
    createTableIfMissing: true,
  }),
  secret: process.env.session_secret ? process.env.session_secret : 'keyboard cat',
  resave: false,
  saveUninitialized: false,
  cookie: { 
//    secure: true, // only for https!!
    maxAge: 30 * 24 * 60 * 60 * 1000,
  },
}));
//app.use(csrf());

app.use(passport.authenticate('session'));

app.use(bodyParser.json({
  strict : true,
  limit: '5mb',
}));

app.use(function (req, res, next) {
  if( req.isAuthenticated() ) {
    res.set('X-FlightGear-User', JSON.stringify(req.user) );
  }
  next();
});

app.use('/api', require('./api/index.js'));
app.use('/auth', require('./auth/index.js')(passport));

module.exports = app;

