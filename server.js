require('dotenv').config()
const ViteExpress = require( "vite-express" );

ViteExpress.listen(
  require('./backend/app.js'),
  port = parseInt(process.env.PORT || '3000', 10), 
  () => console.log("Server is listening...")
);
