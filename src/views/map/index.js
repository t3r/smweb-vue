import "leaflet/dist/leaflet.css"; 
import L from "leaflet";
      
import { createLayers } from "./layers.js";

function Map( ele, props ) {
  const { DefaultBaseLayer, BaseLayer, Overlays } = createLayers();

  const mapDiv = document.getElementById(ele);
  const map = L.map(mapDiv).setView([props.lat||0,props.lon||0], props.z||0);
  DefaultBaseLayer.addTo(map);
  Overlays.Objects.addTo(map);
  L.control.layers(BaseLayer, Overlays).addTo(map);

/* handle resize of map's div */
  const resizeObserver = new ResizeObserver(() => {
    map.invalidateSize();
  });
  resizeObserver.observe(mapDiv);
/* -- */
  return map;
}

export { Map }
