const router = require('express').Router();
const zlib = require('node:zlib');
const obfuscate = require('obfuscate-mail');

const pgformat = require('pg-format');
const db = require('../db.js');

const ContribRequest = require('./ContribRequests.js').ContribRequest;

router.get('/:id?', (req, res ) => {

  let id = Number(req.params.id);

  let WHERE_CLAUSE = '';
  let params = [];
  if( !isNaN(id) ) {
    WHERE_CLAUSE = 'WHERE spr_id = $1';
    params.push( id );
  }

  db.query(`
     SELECT spr_id, spr_hash, spr_base64_sqlz
     FROM fgs_position_requests
     ${WHERE_CLAUSE}
     ORDER BY spr_id`,
     params )
  .then( result => {
    let proms = [];
    result.rows.forEach( row => {
      const req = ContribRequest.fromJson({
        'id': row.spr_id,
        'hash': row.spr_hash,
        'base64_sqlz': row.spr_base64_sqlz,
      });
      proms.push(req.toJson());
    });

    return Promise.all(proms);
  })
  .then( result => {
    if( !isNaN(id) ) {
      result = result[0];
    }
    return res.json(result);
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database error.");
  })

});

module.exports = router;
