import { ref, watchEffect, toValue } from 'vue'

async function fetchJsonByGet( url ) {
  const response = await fetch( url, { method: "GET" });
  if( response.ok )
    return response.json();
}

function SMObject(id, url, opts ) {
  const data = ref(null);
  const error = ref(null);

  watchEffect(() => {
    data.value = null
    error.value = null

    fetch(url(toValue(id)), opts)
      .then((res) => {
        if( res.ok )
          return res.json();
        else
          throw `${res.status} (${res.statusText})`;
      })
      .then((json) => (data.value = json ))
      .catch((err) => (error.value = err))
  })

  return { data, error };
}


export default class SMApi {
  static BASE_URL = '/api';

  static getObjectById(id) {
    return fetchJsonByGet( `${SMApi.BASE_URL}/objects/${id}` );
  }

  static async deleteObjectById(id,props) {
    const res = await fetch( `${SMApi.BASE_URL}/objects/${id}`, { 
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(props),
    });

    if( res.ok )
      return res.json();
    throw `${res.status} (${res.statusText}): ${await res.text()}`
  }

  static _getObjectById(id, loading) {
    const data = ref(null);
    const error = ref(null);

    watchEffect(() => {
      data.value = null
      error.value = null
      const _id = toValue( id );
      if( !_id ) return;

      if( loading ) loading.value = true;
      fetch(`${SMApi.BASE_URL}/objects/${_id}`)
      .then((res) => {
        if( res.ok )
          return res.json();
        else {
          console.error(res);
          throw `${res.status} (${res.statusText}): ${res.text()}`;
        }
      })
      .then((json) => (data.value = json ))
      .catch((err) => (error.value = err))
      .finally( () => {
        if( loading ) loading.value = false;
      });
    })

    return { data, error };
  }

  static getObjectsWithinBounds( bounds, limit ) {
    return fetch(`${SMApi.BASE_URL}/objects?limit=${limit?limit:1000}&e=${bounds.e}&w=${bounds.w}&s=${bounds.s}&n=${bounds.n}`)
    .then((res) => {
    if( res.ok )
      return res.json();
    else
      throw `${res.status} (${res.statusText}): ${res.text()}`;
    })
  }

  static async getObjectByIdAsUpdateRequestContent(id) {
    const obj =  await fetchJsonByGet( `${SMApi.BASE_URL}/objects/${id}` );
    if( obj ) return {
      description: obj.properties.title,
      longitude: obj.geometry.coordinates[0],
      latitude: obj.geometry.coordinates[1],
      offset: obj.properties.elevoffset,
      orientation: obj.properties.heading,
      country: obj.properties.country,
      modelId: obj.properties.model_id,
      objectId: obj.id,
    };
  }

  static getModelTarballUrl(id) {
    return `${SMApi.BASE_URL}/models/${id}/model.tgz`;
  }
  static getModelThumbUrl(id) {
    return `${SMApi.BASE_URL}/models/${id}/thumb.jpg`;
  }

  static getModelById( id ) {
    return SMObject( id, id => `${SMApi.BASE_URL}/models/${id}` );
  }

  static getStats() {
    return SMObject( 0, () => `${SMApi.BASE_URL}/stats` );
  }

  static getMe() {
    return SMObject( 0, () => `${SMApi.BASE_URL}/me` );
  }


  static getModels(options) {
    options = options || {};
    let query = `${SMApi.BASE_URL}/models?limit=${options.limit}&offset=${options.offset}`;
    if( options.shared && !isNaN(options.shared ) )
      query += `&shared=${options.shared}`
    if( options.author && !isNaN(options.author ) )
      query += `&author=${options.author}`
    return fetchJsonByGet( query );
  }

  static getModelPositionsById(id) {
    return SMObject( id, id => `${SMApi.BASE_URL}/models/${id}/positions` );
  }

  static getObjects(options, loading) {
    const data = ref(null);
    const error = ref(null);

    watchEffect(() => {
      data.value = null
      error.value = null
      const o = toValue( options );
      if( !o ) return;

      const limit = o.rowsPerPage;
      const offset = (o.page-1) * limit;

      loading.value = true;
      fetch(`${SMApi.BASE_URL}/objects?limit=${limit}&offset=${offset}`)
      .then((res) => {
        if( res.ok )
          return res.json();
        else
          throw `${res.status} (${res.statusText}): ${res.text()}`;
      })
      .then((json) => (data.value = json ))
      .catch((err) => (error.value = err))
      .finally( () => {
        loading.value = false;
      });
    })

    return { data, error };
  }

  static _getAuthors(options, loading) {
    const data = ref(null);
    const error = ref(null);

    watchEffect(() => {
      data.value = null
      error.value = null
      const o = toValue( options );
      if( !o ) return;

      const limit = o.rowsPerPage;
      const offset = (o.page-1) * limit;

      if( loading ) loading.value = true;
      fetch(`${SMApi.BASE_URL}/authors?limit=${limit}&offset=${offset}`)
      .then((res) => {
        if( res.ok )
          return res.json();
        else
          throw `${res.status} (${res.statusText}): ${res.text()}`;
      })
      .then((json) => (data.value = json ))
      .catch((err) => (error.value = err))
      .finally( () => {
        if( loading ) loading.value = false;
      });
    })

    return { data, error };
  }

  static getAuthors(options) {
    options = options || {};
    options.limit = options.limit || 25;
    options.offset = options.offset || 0;
    let query = `${SMApi.BASE_URL}/authors?limit=${options.limit}&offset=${options.offset}`;
    if( options.order )
      query += `&order=${options.order}`;
    return fetchJsonByGet( query );
  }

  static getContribs(options) {
    options = options || {};
    options.limit = options.limit || 25;
    options.offset = options.offset || 0;
    let query = `${SMApi.BASE_URL}/contribs?limit=${options.limit}&offset=${options.offset}`;
    if( options.order )
      query += `&order=${options.order}`;
    return fetchJsonByGet( query );
  }

  static getContribById(id) {
    return fetchJsonByGet( `${SMApi.BASE_URL}/contribs/${id}` );
  }

  static getAuthorById(id) {
    return fetchJsonByGet( `${SMApi.BASE_URL}/authors/${id}` );
  }


  static MODEL_GROUPS;
  static getModelGroups() {
    if( SMApi.MODEL_GROUPS ) return Promise.resolve(SMApi.MODEL_GROUPS);
    return SMApi.MODEL_GROUPS = fetchJsonByGet( `${SMApi.BASE_URL}/modelgroups` );
  }

  static MODEL_GROUPS_REF = ref(null);
  static _getModelGroups() {
    if( !toValue(SMApi.MODEL_GROUPS_REF) ) {
      SMApi.getModelGroups()
        .then( mg => {
          SMApi.MODEL_GROUPS_REF.value = mg;
        })
        .catch( err => {
          console.error(err);
        });
    }
    return SMApi.MODEL_GROUPS_REF;
  }

  static async getModelGroup( id ) {
    const modelGroups = await SMApi.getModelGroups();
    return modelGroups.find( e => e.id == id );
  }
}
