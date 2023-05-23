const pg = require('pg');

console.log("connecting to", process.env.PGHOST)
const pool = new pg.Pool({ 
//  user: '', //env var: PGUSER
//  database: '', //env var: PGDATABASE
//  password: '', //env var: PGPASSWORD
//  port: 5432, //env var: PGPORT 
  max: 10, // max number of clients in the pool
  idleTimeoutMillis: 30000, // how long a client is allowed to remain idle before being closed
});
      
pool.on('error', function (err, client) {
  // if an error is encountered by a client while it sits idle in the pool
  // the pool itself will emit an error event with both the error and
  // the client which emitted the original error
  // this is a rare occurrence but can happen if there is a network partition
  // between your application and the database, the database restarts, etc.
  // and so you might want to handle it and at least log it out 
  console.error('WARNING: idle client received error', err.messag )
})

async function query( command, args ) {
  const client = await pool.connect();
  try {
    return await client.query( command, args );
  }
  catch( ex ) {
    console.error(`Command failed, command=${command} - args=${args}`);
    throw ex;
  }
  finally {
    client.release();
  }

}

module.exports = {
  query,
  pool,
}


