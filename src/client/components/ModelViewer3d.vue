<template>
  <div
    class="model-viewer-3d"
    role="img"
    :aria-label="ariaLabel"
    :style="{ width: width + 'px', height: height + 'px' }"
  >
    <canvas ref="canvasRef" :width="width" :height="height" />
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onBeforeUnmount } from 'vue'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { legacyJsonToBufferGeometry } from '@/utils/threeJsLegacyToBufferGeometry'

const props = defineProps({
  /** Preview payload: { geometry, textures: [{ name, url }], primaryTexture? } */
  previewData: { type: Object, default: null },
  width: { type: Number, default: 240 },
  height: { type: Number, default: 180 },
  ariaLabel: { type: String, default: '3D preview' },
})

const canvasRef = ref(null)
let viewerScene = null
let viewerAnimationId = null

function cleanup() {
  if (viewerAnimationId != null) {
    cancelAnimationFrame(viewerAnimationId)
    viewerAnimationId = null
  }
  if (viewerScene) {
    viewerScene.controls.dispose()
    viewerScene.renderer.dispose()
    if (viewerScene.mesh?.geometry) viewerScene.mesh.geometry.dispose()
    const mat = viewerScene.mesh?.material
    if (Array.isArray(mat)) mat.forEach((m) => m.dispose())
    else if (mat) mat.dispose()
    viewerScene = null
  }
}

function init() {
  const canvas = canvasRef.value
  const data = props.previewData
  if (!canvas || !data?.geometry) return
  cleanup()

  const geometry = legacyJsonToBufferGeometry(data.geometry)
  if (!geometry) return

  const w = props.width
  const h = props.height
  canvas.width = w
  canvas.height = h

  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0xdddddd)

  const aspect = w / h
  const camera = new THREE.PerspectiveCamera(45, aspect, 0.1, 100000)
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false })
  renderer.setSize(w, h)
  renderer.setPixelRatio(1)

  scene.add(new THREE.AmbientLight(0xffffff, 0.65))
  const dirLight1 = new THREE.DirectionalLight(0xffffff, 0.7)
  scene.add(dirLight1)
  const dirLight2 = new THREE.DirectionalLight(0xffffff, 0.5)
  scene.add(dirLight2)

  const material = new THREE.MeshLambertMaterial({
    color: 0xffffff,
    side: THREE.DoubleSide,
  })
  const mesh = new THREE.Mesh(geometry, material)
  scene.add(mesh)

  const primaryName = data.primaryTexture || (data.textures?.[0]?.name)
  const textureEntry = primaryName
    ? data.textures?.find((t) => t.name === primaryName || t.name.endsWith(primaryName))
    : data.textures?.[0]
  const textureUrl = textureEntry?.url
  if (textureUrl) {
    const loader = new THREE.TextureLoader()
    loader.setCrossOrigin('anonymous')
    loader.load(
      textureUrl,
      (texture) => {
        if (typeof texture.colorSpace !== 'undefined') texture.colorSpace = THREE.SRGBColorSpace
        texture.wrapS = texture.wrapT = THREE.RepeatWrapping
        texture.flipY = true
        if (viewerScene?.mesh) {
          const oldMat = viewerScene.mesh.material
          viewerScene.mesh.material = new THREE.MeshBasicMaterial({
            map: texture,
            side: THREE.DoubleSide,
          })
          if (oldMat) oldMat.dispose()
        }
      },
      undefined,
      () => {}
    )
  }

  const center = geometry.boundingSphere.center.clone()
  const radius = Math.max(geometry.boundingSphere.radius, 1)
  dirLight1.position.set(center.x + radius, center.y + radius, center.z + radius)
  dirLight1.target.position.copy(center)
  scene.add(dirLight1.target)
  dirLight2.position.set(center.x - radius * 0.7, center.y - radius * 0.5, center.z - radius * 0.7)
  dirLight2.target.position.copy(center)
  scene.add(dirLight2.target)

  camera.position.set(center.x + radius * 1.5, center.y + radius * 0.5, center.z + radius * 1.5)
  camera.lookAt(center)
  camera.updateProjectionMatrix()

  const controls = new OrbitControls(camera, renderer.domElement)
  controls.target.copy(center)
  controls.enableDamping = true
  controls.dampingFactor = 0.05

  viewerScene = { renderer, scene, camera, controls, mesh }

  renderer.render(scene, camera)

  function animate() {
    viewerAnimationId = requestAnimationFrame(animate)
    if (viewerScene) {
      viewerScene.controls.update()
      viewerScene.renderer.render(viewerScene.scene, viewerScene.camera)
    }
  }
  animate()
}

watch(
  () => [canvasRef.value, props.previewData],
  ([canvas, data]) => {
    if (!canvas) {
      cleanup()
      return
    }
    if (!data?.geometry) return
    cleanup()
    requestAnimationFrame(() => {
      if (!canvasRef.value || !props.previewData?.geometry) return
      init()
    })
  },
  { flush: 'post' }
)

onBeforeUnmount(cleanup)
</script>

<style scoped>
.model-viewer-3d {
  border-radius: 6px;
  overflow: hidden;
  background: var(--p-surface-100, #f1f5f9);
}
.model-viewer-3d canvas {
  display: block;
  width: 100%;
  height: 100%;
  border-radius: 6px;
}
</style>
