const tar = require('tar');
const router = require('express').Router();

const pgformat = require('pg-format');
const db = require('../db.js');

const MultiStream = require('./multistream.js');

async function GetModels( options ) {
  options.order = options.order || 'mo_id';
  options.desc = options.desc || false;

  const params = [ options.limit, options.offset ]
  let andShared = "";
  let paramIndex=3;
  if( !isNaN(options.shared) ) {
    andShared = ` and mo_shared=\$${paramIndex++}`;
    params.push( options.shared );
  }
  if( !isNaN(options.author) ) {
    andShared += ` and mo_author=\$${paramIndex++}`;
    params.push( options.author );
  }
  const text = pgformat(
    `SELECT mo_id,mo_path,mo_name,mo_notes,mo_shared,mo_modified,mo_author,au_name 
       FROM fgs_models,fgs_authors 
      WHERE au_id=mo_author ${andShared} 
   ORDER BY %I %s LIMIT $1 OFFSET $2`, 
   options.order, options.desc ? 'desc' : 'asc' );

  const result = await db.query( text, params );

  var j = [];
  result.rows.forEach(function(row){
    j.push({
      'id': row.mo_id,
      'filename': row.mo_path,
      'name': row.mo_name,
      'notes': row.mo_notes,
      'shared': row.mo_shared,
      'modified': row.mo_modified,
      'author': row.au_name,
      'authorId': row.mo_author,
    });
  });
  return j;
}

router.get('/:id/positions', (req, res ) => {

  var id = Number(req.params.id || 0);
  if( isNaN(id) ) {
      return res.status(500).send("Invalid Request");
  }

  db.query("select ob_id, ST_AsGeoJSON(wkb_geometry),ob_country,ob_gndelev from fgs_objects where ob_model = $1 order by ob_country", [ id ] )
  .then( result => {

    if( 0 == result.rows.length )
      return res.status(404).send("no positions found");

    var featureCollection = {
      type: "FeatureCollection",
      features: []
    }
    result.rows.forEach(function(r) {
      featureCollection.features.push({
        type: "Feature",
        geometry: JSON.parse(r.st_asgeojson),
        id: r.ob_id,
        properties: {
          id: r.ob_id,
          gndelev: r.ob_gndelev,
          country: r.ob_country,
        }
      }) 
    })
    return res.json(featureCollection)
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database error.");
  })
});

router.get('/:id/model.tgz', (req, res ) => {

  var id = Number(req.params.id || 0);
  if( isNaN(id) ) {
      return res.status(500).send("Invalid Request");
  }

  db.query("select mo_modelfile, mo_modified from fgs_models where mo_id = $1", [ id ] )
  .then( result => {

    if( 0 == result.rows.length )
      return res.status(404).send("model not found");

    if( result.rows[0].mo_modelfile == null ) 
      return res.status(404).send("no modelfile");

    var buf = new Buffer(result.rows[0].mo_modelfile, 'base64');
    res.writeHead(200, {
      'Content-Type': 'application/gzip',
      'Content-Disposition': `attachment;filename="${id}.tgz"`,
      'Last-Modified': result.rows[0].mo_modified,
    });
//Response.AppendHeader("content-disposition", "attachment; filename=\"" + fileName +"\"");
    res.end(buf);
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database error.");
  })
});
router.get('/:id/thumb.jpg', (req, res ) => {

  var id = Number(req.params.id || 0);
  if( isNaN(id) ) {
      return res.status(500).send("Invalid Request");
  }

  db.query("select mo_thumbfile,mo_modified from fgs_models where mo_id = $1", [ id ] )
  .then( result => {

    if( 0 == result.rows.length )
      return res.status(404).send("model not found");

    if( result.rows[0].mo_thumbfile == null ) 
      return res.status(404).send("no thumbfile");

    const buf = new Buffer.from(result.rows[0].mo_thumbfile, 'base64');
    res.writeHead(200, {
      'Content-Type': 'image/jpeg',
      'Last-Modified': result.rows[0].mo_modified ,
//      'ETag': etag(buf),
    });
    res.end(buf);

  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database error.");
  })
});

/*
LIST all with params
offset: number, default 0
limit: number, default 25
shared: number, default undefined
order: string id|name|author|modified, default modified
*/

router.get('/:id', (req, res ) => {
  var id = Number(req.params.id || 0);
  if( isNaN(id) ) {
      return res.status(500).send("Invalid Request");
  }

  db.query(`
    SELECT mo_id,mo_path,mo_modified,mo_author,mo_name,mo_notes,mo_modelfile,mo_shared,au_name,mg_name
    FROM fgs_models 
    LEFT JOIN fgs_modelgroups ON mo_shared=mg_id
    LEFT JOIN fgs_authors ON mo_author=au_id WHERE mo_id = $1`, [ id ] )
  .then( result => {
    if( 0 == result.rows.length )
      return res.status(404).send("model not found")

    var row = result.rows[0]
    var ret = {
        'id': row.mo_id,
        'filename': row.mo_path,
        'modified': row.mo_modified,
        'authorId': row.mo_author,
        'name': row.mo_name,
        'notes': row.mo_notes,
        'shared': row.mo_shared,
        'groupName': row.mg_name,
        'author': row.au_name,
        'authorId': row.mo_author,
        'content': [],
    }
    var streambuf = new MultiStream( new Buffer(result.rows[0].mo_modelfile, 'base64') )
    streambuf.on('end',(a) => { res.json(ret) })

    streambuf.pipe(
      tar.t({
        onentry: entry => { 
          ret.content.push({
            filename: entry.header.path,
            filesize: entry.header.size,
          })
        }
      })
    )
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database error.");
  })

});

router.get('/', (req, res ) => {

  const validOrders = {
    id: "mo_id",
    name: "mo_name",
    author: "au_name",
    modified: "mo_modified",
  }

  let offset = Number(req.query.offset || 0);
  let limit = Number(req.query.limit||25);

  offset = Math.max(0,offset);
  limit = Math.min(10000,Math.max(1,limit));

  if( isNaN(offset) || isNaN(limit) ) {
      return res.status(500).send("Invalid Request");
  }

  let shared;
  if( typeof req.query.shared !== 'undefined' ) {
    if( !isNaN(req.query.shared) )
      shared = Number(req.query.shared);
  }

  let author;
  if( typeof req.query.author !== 'undefined' ) {
    if( !isNaN(req.query.author) )
      author = Number(req.query.author);
  }



  let order = validOrders.modified;
  if( validOrders.hasOwnProperty(req.query.order) ) {
    order = validOrders[req.query.order];
  }
  const desc = req.query.desc ? true : false

  GetModels( {limit,offset,shared,order,desc,author} )
  .then( data => {
    return res.json(data);
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database Error.");
  })

});

module.exports = router;
