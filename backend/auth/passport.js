require('dotenv').config()
const GitHubStrategy = require('passport-github2').Strategy;

const db = require('../db.js');
const pgformat = require('pg-format');
class User {
  constructor(row) {
    this.authorityId = "";
    this.authority = "";
    this.id = -1;
    this.name = "";
    this.email = "";
    this.notes = "";
    this.lastLogin = null;
    if( row ) {
      this.authority = row.eu_authority;
      this.authorityId = row.eu_external_id;
      this.id = row.eu_author_id;
      this.name = row.au_name;
      this.email = row.au_email;
      this.notes = row.au_notes;
      this.lastLogin = row.eu_lastlogin;
    }
  }

  static updateLastlogin( authorityId, id ) {
    return db.query(pgformat(
      'UPDATE fgs_extuserids SET eu_lastlogin=NOW() WHERE eu_authority=$1 AND eu_external_id=$2'),
      [ authorityId, id ] );
  }

  static async findOrCreate( authorityId, id ) {
    await db.query(pgformat(
      'INSERT INTO fgs_extuserids (eu_authority,eu_external_id) VALUES ($1,$2) ON CONFLICT DO NOTHING'),
      [ authorityId, id ] );
    return await User.find(authorityId, id );
  }

  static async find( authorityId, id ) {
    const result = await db.query(pgformat(
      `SELECT eu_external_id,eu_authority,eu_author_id,eu_lastlogin,au_name,au_email,au_notes
       FROM fgs_extuserids 
       LEFT JOIN fgs_authors
         ON au_id=eu_author_id
      WHERE eu_authority=$1
       AND eu_external_id=$2
      `), [ authorityId, id ] );

    if( result.rows && result.rows.length == 1) {
      const u = new User(result.rows[0]);
      return u; 
    }
  }
}

const StrategyConf = {
  'github' : {
    'clientID' : '123',
    'clientSecret' : 'secret',
    'callbackURL' : 'auth/github/callback',
  },
}

// READ OAUTH settings from ENV
for( k in StrategyConf ) {
  const conf = process.env["OAUTH_" + k]
  if( !conf ) continue
  try {
    StrategyConf[k] = JSON.parse( conf )
  }
  catch {
    console.error("can't parse OAUTH config",conf)
  }
}

function getCallbackUrl(suffix) {
  var urlPrefix = 'http://localhost:3000/';
  if( process.env.node_env !== 'development' ) {
    urlPrefix = process.env.urlprefix;
    if( !urlPrefix ) {
      console.log("urlprefix environment not set!")
      urlPrefix = "";
    }
  }
  urlPrefix = urlPrefix.replace(/\/+$/, "")
  return urlPrefix + "/" + suffix.replace(/^\/+/, "")
}


module.exports = function(passport) {

  passport.serializeUser(function(user, done) {
    done(null, {a:'github', b:user.authorityId});
  });

  passport.deserializeUser(function(u, done) {
    User.find( u.a, u.b )
    .then( user => {
      done(null,user)
    })
    .catch( err => {
      done(err)
    })
  });

  passport.use(new GitHubStrategy({
    clientID : StrategyConf.github.clientID,
    clientSecret : StrategyConf.github.clientSecret,
    callbackURL : getCallbackUrl(StrategyConf.github.callbackURL),
  }, function(token, refreshToken, profile, done) {
//    console.log("github callback", "profile", profile, "token", token, "refreshToken", refreshToken )
    User.findOrCreate( 'github', profile.id )
    .then( user => {
      return done(null, user)
    })
    .catch( err => {
        console.error(`Error findOrCreate('github',${profile.id})`, err);
        return done(null, null)
    })
  }));
};
