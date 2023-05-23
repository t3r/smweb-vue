const router = require('express').Router();
const cors = require('cors');

router.use(cors());

[ 
  "modelgroups",
  "authors",
  "models",
  "objects",
  "contribs",
  "auth",
  "stats",
].forEach( r => router.use( `/${r}/`, require( `./${r}.js` ) ) );

router.get('/me', (req,res) => {
    return res.json(req.user);
})

router.use('*', (_, res) => res.status(404).send("API not found."));

module.exports = router;

