require('dotenv').config()
const ViteExpress = require( "vite-express" );

if( "production" === process.env.NODE_ENV )
  ViteExpress.config({ mode: "production" });

ViteExpress.listen(
  require('./backend/app.js'),
  port = parseInt(process.env.PORT || '3000', 10), 
  () => console.log("Server is listening...")
);
