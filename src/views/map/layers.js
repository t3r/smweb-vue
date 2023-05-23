import { ObjectsLayer } from "./objectslayer.js";
import SMApi from "../../services/smapi.js";

function createLayers() {
  const  BaseLayer = {
    OSM: L.tileLayer(
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        minZoom : 3,
        maxZoom : 19,
        attribution : 'Map data &copy; <a target="_blank" href="http://openstreetmap.org">OpenStreetMap</a> contributors'
      }),
    "Esri World Imagery": L.tileLayer(
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
         minZoom : 3,
         maxZoom : 19,
        attribution: '&copy; <a href="http://www.esri.com/">Esri</a>, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
      }),
  }

  const  Overlays = {
    "Objects": new ObjectsLayer(null,{
      attribution : 'Scenery data &copy; <a target="_blank" href="https://flightgear.org">FlightGear</a> contributors',
      minZoom : 10,
      fetchObjects: function(bounds) {
        return SMApi.getObjectsWithinBounds({
          s: bounds.getSouth(),
          n: bounds.getNorth(),
          e: bounds.getEast(),
          w: bounds.getWest()
        });
      },
    }),
  }

  const DefaultBaseLayer = BaseLayer.OSM;
  return { BaseLayer, Overlays, DefaultBaseLayer, createLayers }
}

export { createLayers }
