const router = require('express').Router();
const pgformat = require('pg-format');
const db = require('../db.js');

function toFeature( row ) {
  return {
        'type': 'Feature',
        'id': row['ob_id'],
        'geometry':{
          'type': 'Point','coordinates': [row['ob_lon'], row['ob_lat']]
        },
        'properties': {
          'id': row['ob_id'],
          'heading': row['ob_heading'],
          'title': row['ob_text'],
          'gndelev': row['ob_gndelev'],
          'elevoffset': row['ob_elevoffset'],
          'model_id': row['ob_model'],
          'model_name': row['mo_name'],
          'shared': row['mo_shared'],
          'groupName': row.mg_name,
          'stg': row['obpath'] + row['ob_tile'] + '.stg',
          'country': row['ob_country'],
        }
      }
}

function toFeatureCollection(rows,totalRows) {
  var reply = {
        'type': 'FeatureCollection',
        'features': [],
        'properties': {
          totalRows
        }
  }

  if( rows && Array.isArray(rows) ) rows.forEach(function(row) {
      reply.features.push(toFeature(row));
  })
  return reply;
}

async function GetObjects( options ) {
  options.order = options.order || 'ob_id';
  options.desc = options.desc || false;

  const params = [ options.limit, options.offset ]
  let ANDs = "";

  if( options.bounds ) {
    const w = Number(options.bounds.w);
    const e = Number(options.bounds.e);
    const n = Number(options.bounds.n);
    const s = Number(options.bounds.s);

    ANDs += pgformat(
      " AND ST_Within(wkb_geometry, ST_GeomFromText('POLYGON((%s %s,%s %s,%s %s,%s %s,%s %s))',4326))",
      w, s, w, n, e, n, e, s, w, s );
  }

  const countQuery = `SELECT count(*) FROM fgs_objects WHERE 1=1 ${ANDs}`;
  let result = await db.query( countQuery );
  const totalRows = Number(result.rows[0].count);

  const text = pgformat(
    `SELECT ob_id, ob_text, ob_country, ob_model,
            ST_Y(wkb_geometry) AS ob_lat, ST_X(wkb_geometry) AS ob_lon,
           ob_heading, ob_gndelev, ob_elevoffset, mo_shared, mo_name,
           concat('Objects/', fn_SceneDir(wkb_geometry), '/', fn_SceneSubDir(wkb_geometry), '/') AS obpath,
           ob_tile, mg_name
       FROM fgs_objects
       LEFT JOIN fgs_models ON fgs_models.mo_id=fgs_objects.ob_model
       LEFT JOIN fgs_modelgroups ON fgs_models.mo_shared=fgs_modelgroups.mg_id
      WHERE 1=1 ${ANDs}
      ORDER by %I %s LIMIT $1 OFFSET $2`,
      options.order, options.desc ? 'desc' : 'asc' );

  result = await db.query( text, params );
  return toFeatureCollection( result.rows, totalRows );
}

router.get('/:id', (req, res ) => {
  var id = Number(req.params.id || 0);
  if( isNaN(id) ) {
      return res.status(500).send("Invalid Request");
  }

  const params = [ id ];
  const text = `SELECT ob_id, ob_text, ob_country, ob_model,
          ST_Y(wkb_geometry) AS ob_lat, ST_X(wkb_geometry) AS ob_lon,
         ob_heading, ob_gndelev, ob_elevoffset, mo_shared, mo_name,
         concat('Objects/', fn_SceneDir(wkb_geometry), '/', fn_SceneSubDir(wkb_geometry), '/') AS obpath,
         ob_tile, mg_name
     FROM fgs_objects
     LEFT JOIN fgs_models ON fgs_models.mo_id=fgs_objects.ob_model
     LEFT JOIN fgs_modelgroups ON fgs_models.mo_shared=fgs_modelgroups.mg_id
    WHERE fgs_objects.ob_id=$1`;

  db.query( text, params )
  .then( result => {
    if( 0 == result.rows.length )
      return res.status(404).send("object not found");

    return res.json(toFeature(result.rows[0]));
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database Error.");
  })

});

router.put('/:id', (req, res ) => {
  console.log("Updating", req.params.id, req.body );
  return res.status(202).json({ status: 'queued', requestId: 4712 });
});

router.delete('/:id', (req, res ) => {
  console.log("Deleting", req.params.id, req.body );
  return res.status(202).json({ status: 'queued', requestId: 4711 });
});

// Create new Object
router.post('/', (req, res ) => {
  return res.status(400).json({status: 'not implemented'});
  // return 201, Location: /:id
});

router.get('/', (req, res ) => {

  const validOrders = {
    id: "ob_id",
    country: "ob_country",
    model: "mo_name",
    description: "ob_text"
  }

  let offset = Number(req.query.offset || 0);
  let limit = Number(req.query.limit||25);

  let bounds;
  if( 'e' in req.query &&
      'w' in req.query &&
      'n' in req.query &&
      's' in req.query ) {
    const e = Number(req.query.e);
    const w = Number(req.query.w);
    const n = Number(req.query.n);
    const s = Number(req.query.s);
    if( !(isNaN(e)||isNaN(w)||isNaN(n)||isNaN(s)) ) {
      bounds = { e, w, n, s };
    }
  }

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

  GetObjects( {limit,offset,order,desc,bounds} )
  .then( data => {
    return res.json(data);
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database Error.");
  })
});

module.exports = router;
