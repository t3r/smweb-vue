const router = require('express').Router();
const db = require('../db.js');

router.get('/', (req, res ) => {

  db.query(`
    WITH
      t1 AS (SELECT COUNT(*) objects FROM fgs_objects),
      t2 AS (SELECT COUNT(*) models FROM fgs_models),
      t3 AS (SELECT COUNT(*) authors FROM fgs_authors),
      t4 AS (SELECT count(*) NAVAIDS FROM fgs_navaids),
      t5 AS (SELECT COUNT(*) pends FROM fgs_position_requests),
      t6 AS (SELECT COUNT(*) gndelevs FROM fgs_objects WHERE ob_gndelev=-9999)
        SELECT objects, models, authors, navaids, pends, gndelevs FROM t1, t2, t3, t4, t5, t6
     `, )
  .then( result => {
    var row = result.rows.length ? result.rows[0] : {};
    res.json({ 
      'stats': { 
        'objects': row.objects || 0,
        'models':  row.models || 0,
        'authors': row.authors || 0,
        'navaids': row.navaids || 0,
        'pending': row.pends || 0,
        'elev': row.gndelevs || 0,
      }
    });
  })
  .catch( err => {
    console.error(err);
    return res.status(500).send("Database error.");
  })

});

module.exports = router;
