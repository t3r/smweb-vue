<script setup>
import { reactive, ref } from 'vue';

import SMApi from '../services/smapi.js';
import ModelGroupCombobox from '../components/ModelGroupCombobox.vue';

const model = reactive({
  group: 0,
  name: '',
  description: '',
  ac3d: null,
  xml: null,
  textures: [],
  thumb: null,
  longitude: 0.0,
  latitude: 0.0,
  offset: 0,
  heading: 0,
});

function handleFileUpload( evt, f ) {
  if( "textures" === f ) model.textures = evt.target.files;
  else if( f in model ) model[f] = evt.target.files[0];
}

async function submit() {
  const response = await SMApi.createModel( model );
  if( response.status == 201 ) alert('model accepted');
  if( response.status == 202 ) alert('request queued');
}

</script>

<template>
<main>
<h1>Add a Model</h1>
<p>
  <h2>Rules and Guidlines</h2>
  <ul>
    <li> Files have to share a common name, for instance: modelname.ac, modelname.xml and modelname.png.</li>
    <li>Do not group separate buildings into one AC file. The terrain elevation is subject to updates, so this could lead to inaccuracies.</li>
    <li>Do not add trees or flat surfaces (such as soccer fields) into your AC file.</li>
    <li>PNG resolution must be a power of 2 in width and height.</li>
    <li>If you have multiple textures, name them modelname1.png, modelname2.png etc.</li>
    <li>XML file must start with a classic XML header, such as: &lt;?xml version="1.0" encoding="UTF-8" ?&gt;. See here for a quick example. Only include XML if necessary for the model.</li>
    <li>The thumbnail must be in JPEG and 320*240 resolution.</li>
  </ul>
</p>
<p>
  <ul class="nav nav-tabs" id="myTab" role="tablist">
    <li class="nav-item" role="presentation">
      <button class="nav-link active" id="model-tab" 
              data-bs-toggle="tab" data-bs-target="#model-tab-pane" 
              type="button" role="tab" aria-controls="model-tab-pane" aria-selected="true">Model</button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link" id="location-tab" 
              data-bs-toggle="tab" data-bs-target="#location-tab-pane" 
              type="button" role="tab" aria-controls="location-tab-pane" aria-selected="false">Location</button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link" id="submit-tab" 
              data-bs-toggle="tab" data-bs-target="#submit-tab-pane" 
              type="button" role="tab" aria-controls="submit-tab-pane" aria-selected="false">Submit</button>
    </li>
  </ul>
  <div class="tab-content" id="myTabContent">
    <div class="tab-pane fade show active" id="model-tab-pane" role="tabpanel" aria-labelledby="model-tab" tabindex="0">
      <form>
        <div class="row mb-3">
          <label for="modelGroup" class="col-sm-2 col-form-label">Model Group</label>
          <div class="col-sm-10">
            <ModelGroupCombobox class="form-control" id="modelGroup" aria-describedby="modelGroupHelp" v-model="model.group"/>
          </div>
          <div id="modelGroupHelp" class="form-text">Select the group this model belongs to</div>
        </div>

        <div class="row mb-3">
          <label for="modelName" class="col-sm-2 col-form-label">Name</label>
          <div class="col-sm-10">
            <input type="text" maxlength="100" minlength="1" placeholder="Rocky Beach Town Hall" 
                   class="form-control" id="modelName" aria-describedby="modelNameHelp" v-model="model.name"/>
          </div>
          <div id="modelNameHelp" class="form-text">A short and descriptive name of your model not longer than 100 characters)</div>
        </div>

        <div class="row mb-3">
          <label for="modelDescription" class="col-sm-2 col-form-label">Description</label>
          <div class="col-sm-10">
            <input type="text" maxlength="100" minlength="1" placeholder="Rocky Beach Town Hall, as shown on satellite images and OSM data" 
                   class="form-control" id="modelDescription" aria-describedby="modelDescriptionHelp" v-model="model.description"/>
          </div>
          <div id="modelDescriptionHelp" class="form-text">A more detailed text describing the model (optional)</div>
        </div>

        <div class="row mb-3">
          <label for="modelAc3d" class="col-sm-2 col-form-label">AC3D-File</label>
          <div class="col-sm-10">
            <input type="file" id="modelAc3d" class="form-control" aria-describedby="modelAc3dHelp"
                   @change="handleFileUpload($event,'ac3d')"/>
          </div>
          <div id="modelAc3dHelp" class="form-text">The 3d model file in AC3D format</div>
        </div>

        <div class="row mb-3">
          <label for="modelXml" class="col-sm-2 col-form-label">Xml-File</label>
          <div class="col-sm-10">
            <input type="file" id="modelXml" class="form-control" aria-describedby="modelXmlHelp"
                   @change="handleFileUpload($event,'xml')"/>
          </div>
          <div id="modelXmlHelp" class="form-text">The XML file for the model</div>
        </div>

        <div class="row mb-3">
          <label for="modelTexture" class="col-sm-2 col-form-label">Texture-File(s)</label>
          <div class="col-sm-10">
            <input type="file" id="modelTexture" class="form-control" aria-describedby="modelTextureHelp" multiple
                   @change="handleFileUpload($event,'textures')"/>
          </div>
          <div id="modelTextureHelp" class="form-text">The texture file(s) for the model in PNG format</div>
        </div>

        <div class="row mb-3">
          <label for="modelThumb" class="col-sm-2 col-form-label">320x240 JPEG thumbnail</label>
          <div class="col-sm-10">
            <input type="file" id="modelThumb" class="form-control" aria-describedby="modelThumbHelp"
                   @change="handleFileUpload($event,'thumb')"/>
          </div>
          <div id="modelThumbHelp" class="form-text">A nice picture representing your model within FlightGear in the best way</div>
        </div>
      </form>
    </div>

    <div class="tab-pane fade" id="location-tab-pane" role="tabpanel" aria-labelledby="location-tab" tabindex="0">
      <form>
        <div class="row mb-3">
          <label for="modelLongitude" class="col-sm-2 col-form-label">Longitude</label>
          <div class="col-sm-10">
            <input type="number" min="-180" max="180" step="0.000001" placeholder="1.234567" 
                   class="form-control" id="modelLongitude" aria-describedby="modelLongitudeHelp" v-model="model.longitude"/>
          </div>
          <div id="modelLongitudeHelp" class="form-text">The WGS84 longitude of this objects position. Negative values are west.</div>
        </div>

        <div class="row mb-3">
          <label for="modelLatitude" class="col-sm-2 col-form-label">Latitude</label>
          <div class="col-sm-10">
            <input type="number" min="-90" max="90" step="0.000001" placeholder="-1.234567" 
                   class="form-control" id="modelLatitude" aria-describedby="modelLatitudeHelp" v-model="model.latitude"/>
          </div>
          <div id="modelLatitudeHelp" class="form-text">The WGS84 latitude of this objects position. Negative values are south.</div>
        </div>

        <div class="row mb-3">
          <label for="modelOffset" class="col-sm-2 col-form-label">Offset</label>
          <div class="col-sm-10">
            <input type="number" step="0.1" placeholder="1.234567" 
                   class="form-control" id="modelOffset" aria-describedby="modelOffsetHelp" v-model="model.offset"/>
          </div>
          <div id="modelOffsetHelp" class="form-text">Vertical offset in meters. Negative numbers sinks into the ground.</div>
        </div>

        <div class="row mb-3">
          <label for="modelHeading" class="col-sm-2 col-form-label">Heading</label>
          <div class="col-sm-10">
            <input type="number" min="0" max="360" step="0.1" placeholder="1.234567" 
                   class="form-control" id="modelHeading" aria-describedby="modelHeadingHelp" v-model="model.heading"/>
          </div>
          <div id="modelHeadingHelp" class="form-text">Heading</div>
        </div>

      </form>
    </div>

    <div class="tab-pane fade" id="submit-tab-pane" role="tabpanel" aria-labelledby="submit-tab" tabindex="0">
    <div>
      <form>
        <div class="row mb-3">
          <button type="button" class="btn btn-primary" @click="submit()">Submit</button>
        </div>
      </form>
    </div>
    </div>
  </div>
</p>
<p>
{{ model }} 
</p>
</main>
</template>
