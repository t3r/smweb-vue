const router = require('express').Router();

const pgformat = require('pg-format');
const db = require('../db.js');

async function GetModelgroups( options ) {
  options.order = options.order || 'mg_id';
  options.desc = options.desc || false;

  const text = pgformat(
    `SELECT mg_id, mg_name, mg_path
       FROM fgs_modelgroups
   ORDER BY %I %s LIMIT $1 OFFSET $2`, 
   options.order, options.desc ? 'desc' : 'asc' );

  const params = [ options.limit, options.offset ];
  const result = await db.query( text, params );
  var reply = []

  result.rows.forEach(function(row) {
    reply.push({
      'id': Number(row.mg_id),
      'name': row.mg_name,
      'path': row.mg_path,
    })
  })

  return reply;
}

router.get('/', (req, res ) => {

  const validOrders = {
    id: "ob_id",
  }

  let offset = Number(req.query.offset || 0);
  let limit = Number(req.query.limit||25);

  offset = Math.max(0,offset);
  limit = Math.min(10000,Math.max(1,limit));

  if( isNaN(offset) || isNaN(limit) ) {
      return res.status(500).send("Invalid Request");
  }

  let order = validOrders.modified;
  if( validOrders.hasOwnProperty(req.query.order) ) {
    order = validOrders[req.query.order];
  }
  const desc = req.query.desc ? true : false

  GetModelgroups( {limit,offset,order,desc} )
  .then( data => {
    return res.json(data);
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database Error.");
  })
});

module.exports = router;

