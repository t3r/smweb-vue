const express = require('express');
const router = express.Router();

const pgformat = require('pg-format');
const db = require('../db.js');

async function GetAuthors( options ) {
  options.order = options.order || 'ob_id';
  options.desc = options.desc || false;

  const params = [ options.limit, options.offset ]
  const text = pgformat(
    `SELECT au_id, au_name, au_notes,count(mo_id) AS count 
     FROM fgs_authors,fgs_models 
     WHERE au_id=mo_author group by au_id 
     ORDER BY %I %s LIMIT $1 OFFSET $2`,
      options.order, options.desc ? 'desc' : 'asc' );

  const result = await db.query( text, params );
  var j = [];
  result.rows.forEach(function(row){
    j.push({
      'id': row.au_id,
      'name': row.au_name,
      'notes': row.au_notes,
      'models': row.count,
    });
  });

  return j;
}

router.get('/', (req, res ) => {

  const validOrders = {
    id: "au_id",
    name: "au_name",
    count: "count",
  }

  let offset = Number(req.query.offset || 0);
  let limit = Number(req.query.limit||25);

  offset = Math.max(0,offset);
  limit = Math.min(10000,Math.max(1,limit));

  if( isNaN(offset) || isNaN(limit) ) {
      return res.status(500).send("Invalid Request");
  }

  let order = validOrders.id;
  if( validOrders.hasOwnProperty(req.query.order) ) {
    order = validOrders[req.query.order];
  }
  const desc = req.query.desc ? true : false

  GetAuthors( {limit,offset,order,desc} )
  .then( data => {
    return res.json(data);
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database Error.");
  })
});

router.get('/:id', (req, res ) => {
  var id = Number(req.params.id || 0);
  if( isNaN(id) ) {
      return res.status(500).send("Invalid Request");
  }

  db.query(`
     SELECT au_id, au_name, au_notes,count(mo_id) AS count
     FROM fgs_authors,fgs_models
     WHERE au_id=mo_author and au_id=$1 group by au_id`,
     [ id ] )
  .then( result => {
    if( 0 == result.rows.length )
      return res.status(404).send("model not found")

    var row = result.rows[0]
    var ret = {
      'id': row.au_id,
      'name': row.au_name,
      'notes': row.au_notes,
      'models': row.count,
    } 
    return res.json(ret);
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database error.");
  })

});

module.exports = router;
