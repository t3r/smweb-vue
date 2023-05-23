const MultiStream = require('./multistream.js');
const tar = require('tar');
const zlib = require('node:zlib');
const obfuscate = require('obfuscate-mail');
const WritableStream = require('./WriteableStream.js');
const fs = require('fs');
const util = require('util');
const path = require('path');
const os = require('os');

const mkdtemp = util.promisify( fs.mkdtemp );

class ContribRequest {
  constructor( rawData ) {
    this.rawData = rawData || {};
  }

  get content() {
    return this.request.content;
  }

  get comment() {
    return this.request.comment;
  }

  get id() {
    return this.rawData.id;
  }

  get hash() {
    return this.rawData.hash;
  }

  get request() {
    if( !this.rawData.request ) {
      this.rawData.request = JSON.parse(zlib.unzipSync(Buffer.from(base64_sqlz, 'base64')).toString('utf-8'));
      this.rawData.request.email = obfuscate( this.rawData.request.email );
    }
    return this.rawData.request;
  }

  toJson() {
    const reply = {
      id: this.id,
      hash: this.hash,
      request: this.request,
    }
    return Promise.resolve(reply);
  }

  static getRequest( b64 ) {
    const r = JSON.parse(zlib.unzipSync(Buffer.from(b64, 'base64')).toString('utf-8'));
    r.email = obfuscate( r.email );
    return r;
  }

  static fromJson( json ) {
    const factory = {
      MODEL_ADD: ModelAddRequest,
      MODEL_UPDATE: ModelUpdateRequest,
      OBJECTS_ADD: ObjectsAddRequest,
      OBJECT_UPDATE: ObjectsUpdateRequest,
      OBJECT_DELETE: ObjectDeleteRequest,
    }
    json.request = ContribRequest.getRequest(json.base64_sqlz);
    if( json.request.type && json.request.type in factory )
      return new factory[json.request.type](json);
    else
      console.error("unknown request:", json.request.type );
  }
}

class ModelAddRequest extends ContribRequest {
  get model() {
    return this.content.model;
  }

  get modelfiles() {
    return this.model.modelfiles;
  }

  async toJson() {

   const reply = {
     id: this.id,
     hash: this.hash,
     request: this.request,
   }
   reply.request.content.model.modelfiles = await ModelAddRequest.getModelfilesList( this.request.content.model.modelfiles );
   return Promise.resolve(reply) ;
  }

  static async getModelfilesList(tardata) {
    const cwd = await mkdtemp( path.join(os.tmpdir(), 'req-') );
    return new Promise((resolve,reject) => {
      const ret = [];
      const streambuf = new MultiStream( Buffer.from(tardata, 'base64') )

      streambuf.pipe(
        tar.x({
          cwd,
          transform(entry) {
            let s = new WritableStream();
            ret.push({
              filename: entry.header.path,
              filesize: entry.header.size,
              data: s,
            });
            return s;
          },
        })
      )
      .on('end', () => {
        fs.rmSync(cwd, { recursive: true, force: true });
        resolve(ret)
      });
    });
  }
}

class ModelUpdateRequest extends ContribRequest {
}

class ObjectsAddRequest extends ContribRequest {
}

class ObjectsUpdateRequest extends ContribRequest {
}

class ObjectDeleteRequest extends ContribRequest {
}

module.exports = {
  ContribRequest,
  ModelAddRequest,
  ModelUpdateRequest,
  ObjectsAddRequest,
  ObjectsUpdateRequest,
  ObjectDeleteRequest,
};
