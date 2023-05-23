function markerSvg(heading) {
  return `
  <svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="xMinYMin meet">
    <circle cx="50" cy="50" r="25" stroke="black" fill="none" stroke-width="3" />
    <g id="arrow" transform="rotate(${Number(heading)||0} 50 50)">
      <line x1="50" y1="50" x2="50" y2="2" stroke="black" stroke-width="3" stroke-linecap="round"/>
      <line x1="40" y1="20" x2="50" y2="2" stroke="black" stroke-width="3" stroke-linecap="round"/>
      <line x1="60" y1="20" x2="50" y2="2" stroke="black" stroke-width="3" stroke-linecap="round"/>
    </g>
  </svg>`
}

function objectDetails(layer) {
  const feature = layer.feature;
  const zoom = layer._map.getZoom();
  return `
    <table>
    <tr>
      <td><img width="160" height="120" alt="${feature.properties.title}" title="${feature.properties.title}" src="/api/models/${feature.properties.model_id}/thumb.jpg"></img></td>
      <td>
        <ul style="list-style:none;padding-left:0.5em">
          <li>Heading: ${feature.properties.heading||0}&deg;</li>
          <li>Elevation: ${feature.properties.gndelev||0}m</li>
          <li>Offset: ${feature.properties.elevoffset||0}m</li>
          <li>STG: <a target="_blank" href="http://flightgear.sourceforge.net/scenery/${feature.properties.stg}">link</a></li>
          <li><a href='/#/map?lat=${feature.geometry.coordinates[1]}&lon=${feature.geometry.coordinates[0]}&z=${zoom}&obj=${feature.properties.model_id}'>permalink</a></li>
          <li>
            <div class="btn-group" role="group">
              <a href="/#/contrib/object/update/${feature.id}" class="btn btn-link"><i class="bi bi-pencil"></i></a>
              <a href="/#/contrib/object/delete/${feature.id}" class="btn btn-link"><i class="bi bi-trash"></i></a>
            </div>
          </li>
        </ul>
      </td>
    </tr>
    </table>
  `;
}

const ObjectsLayer = L.GeoJSON.extend({

  options: {
    fetchObjects(bounds) { console.error("fetchObjects not defined") },

    pointToLayer(feature, latlng) {
      const marker = L.marker(latlng, {
        icon: L.divIcon({
          className: feature.properties.shared > 0 ? 'object-marker-shared' : 'object-marker-static',
          html: markerSvg(feature.properties.heading),
          iconSize: [ 32, 32 ],
          iconAnchor: [ 16, 16 ],
        }),
        contextmenu: true,
        contextmenuItems: [{
          text: 'Mark object',
          callback: function(e) {
            SelectedObject = feature.properties.id;
          },                                                  
        }]
      });
      return marker;
    },

    onEachFeature(feature, layer) {
      layer.bindPopup(objectDetails, {
        autoPan: false
      });
    },
  },

  onAdd(map) {
    L.GeoJSON.prototype.onAdd.call(this, map);
    this._refresh();
    map.on("moveend", this._refresh, this );
    map.on("zoomstart", this._refresh, this );
  },

  onRemove(map) {
    map.off("zoomstart", this._refresh, this );
    map.off("moveend", this._refresh, this );
    L.GeoJSON.prototype.onRemove.call(this, map);
  },


  _zoomstart(evt) {
    console.log("Zoom",evt);
  },

  _refresh() {
    this.options.fetchObjects( this._map.getBounds() )
    .then( data => {
      this.clearLayers();
      this.addData(data);
    })
    .catch( err => {
      console.error( "Failed to load Objects!", err );
    });
  },
});

export { ObjectsLayer }
