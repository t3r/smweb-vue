<template>
  <div
    class="gltf-viewer-3d"
    role="img"
    :aria-label="ariaLabel"
    :style="{ width: width + 'px', height: height + 'px' }"
  >
    <div v-if="status === 'loading'" class="gltf-viewer-3d__overlay">
      <i class="pi pi-spin pi-spinner" aria-hidden="true"></i>
      <span class="sr-only">Loading 3D model</span>
    </div>
    <canvas ref="canvasRef" :width="width" :height="height" />
    <p v-if="status === 'error'" class="gltf-viewer-3d__error-overlay m-0 text-color-secondary">
      {{ errorMessage }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, onBeforeUnmount } from 'vue'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'
import { mapGltfLoaderUrlToResolve } from '@/utils/gltfPreview'

const props = withDefaults(
  defineProps<{
    /** Full URL to the root .gltf or .glb (same-origin; session cookies apply). */
    modelUrl: string
    /**
     * Resolve any referenced file in the glTF (buffers, images) to a fetchable URL.
     * `fileName` is the flat basename from the asset (e.g. scene.bin, albedo.png).
     */
    resolveFileUrl: (fileName: string) => string
    width?: number
    height?: number
    ariaLabel?: string
  }>(),
  {
    width: 240,
    height: 180,
    ariaLabel: 'glTF 3D preview',
  }
)

const canvasRef = ref<HTMLCanvasElement | null>(null)
const status = ref<'idle' | 'loading' | 'ready' | 'error'>('idle')
const errorMessage = ref('Could not load glTF preview.')

type ViewerScene = {
  renderer: THREE.WebGLRenderer
  scene: THREE.Scene
  camera: THREE.PerspectiveCamera
  controls: OrbitControls
  root: THREE.Group
  mixer: THREE.AnimationMixer | null
  clock: THREE.Clock
}

let viewer: ViewerScene | null = null
let animationId: number | null = null
let loadGeneration = 0

function disposeObject3D(obj: THREE.Object3D) {
  obj.traverse((child) => {
    const mesh = child as THREE.Mesh
    if (mesh.isMesh) {
      mesh.geometry?.dispose()
      const mat = mesh.material
      if (Array.isArray(mat)) {
        mat.forEach((m) => {
          disposeMaterial(m)
        })
      } else if (mat) {
        disposeMaterial(mat)
      }
    }
  })
}

function disposeMaterial(m: THREE.Material) {
  m.dispose()
  const anyM = m as THREE.MeshStandardMaterial & { map?: THREE.Texture }
  const maps = ['map', 'normalMap', 'roughnessMap', 'metalnessMap', 'aoMap', 'emissiveMap'] as const
  for (const key of maps) {
    const t = anyM[key] as THREE.Texture | undefined
    t?.dispose()
  }
}

function cleanup() {
  if (animationId != null) {
    cancelAnimationFrame(animationId)
    animationId = null
  }
  if (viewer) {
    viewer.controls.dispose()
    viewer.renderer.dispose()
    disposeObject3D(viewer.root)
    viewer = null
  }
}

async function initViewer() {
  const canvas = canvasRef.value
  const modelUrl = (props.modelUrl || '').trim()
  if (!canvas || !modelUrl) {
    cleanup()
    status.value = 'error'
    errorMessage.value = 'No glTF URL.'
    return
  }

  const gen = ++loadGeneration
  cleanup()
  status.value = 'loading'
  errorMessage.value = 'Could not load glTF preview.'

  const w = props.width
  const h = props.height
  canvas.width = w
  canvas.height = h

  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0xdddddd)

  const aspect = w / h
  const camera = new THREE.PerspectiveCamera(45, aspect, 0.01, 1_000_000)
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false })
  renderer.setSize(w, h)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2))
  if ('outputColorSpace' in renderer) {
    renderer.outputColorSpace = THREE.SRGBColorSpace
  }
  renderer.toneMapping = THREE.ACESFilmicToneMapping

  scene.add(new THREE.AmbientLight(0xffffff, 0.55))
  const key = new THREE.DirectionalLight(0xffffff, 0.85)
  key.position.set(4, 8, 6)
  scene.add(key)
  const fill = new THREE.DirectionalLight(0xffffff, 0.35)
  fill.position.set(-5, 3, -4)
  scene.add(fill)

  const manager = new THREE.LoadingManager()
  manager.setURLModifier((url) => {
    try {
      return mapGltfLoaderUrlToResolve(url, props.resolveFileUrl)
    } catch {
      return url
    }
  })

  const loader = new GLTFLoader(manager)

  let loadedRoot: THREE.Object3D | null = null
  try {
    const gltf = await loader.loadAsync(modelUrl)
    if (gen !== loadGeneration) {
      disposeObject3D(gltf.scene)
      renderer.dispose()
      return
    }
    const root = gltf.scene
    loadedRoot = root
    scene.add(root)

    const box = new THREE.Box3().setFromObject(root)
    if (box.isEmpty()) {
      throw new Error('Empty model bounds')
    }
    const center = box.getCenter(new THREE.Vector3())
    const size = box.getSize(new THREE.Vector3())
    const maxDim = Math.max(size.x, size.y, size.z, 1e-6)

    camera.position.set(center.x + maxDim * 1.2, center.y + maxDim * 0.6, center.z + maxDim * 1.2)
    camera.lookAt(center)
    camera.updateProjectionMatrix()

    const controls = new OrbitControls(camera, renderer.domElement)
    controls.target.copy(center)
    controls.enableDamping = true
    controls.dampingFactor = 0.06

    const clock = new THREE.Clock()
    let mixer: THREE.AnimationMixer | null = null
    if (gltf.animations?.length) {
      mixer = new THREE.AnimationMixer(root)
      for (const clip of gltf.animations) {
        mixer.clipAction(clip).play()
      }
    }

    viewer = { renderer, scene, camera, controls, root, mixer, clock }
    loadedRoot = null
    status.value = 'ready'

    function animate() {
      animationId = requestAnimationFrame(animate)
      if (!viewer) return
      const delta = viewer.clock.getDelta()
      viewer.mixer?.update(delta)
      viewer.controls.update()
      viewer.renderer.render(viewer.scene, viewer.camera)
    }
    animate()
  } catch {
    if (gen !== loadGeneration) return
    if (loadedRoot) {
      scene.remove(loadedRoot)
      disposeObject3D(loadedRoot)
    }
    renderer.dispose()
    status.value = 'error'
    errorMessage.value = 'Could not load glTF preview.'
  }
}

onMounted(() => {
  void initViewer()
})

watch(
  () => props.modelUrl,
  () => {
    void initViewer()
  }
)

watch(
  () => [props.width, props.height],
  () => {
    if (!viewer || !canvasRef.value) return
    const w = props.width
    const h = props.height
    canvasRef.value.width = w
    canvasRef.value.height = h
    viewer.camera.aspect = w / h
    viewer.camera.updateProjectionMatrix()
    viewer.renderer.setSize(w, h)
  }
)

onBeforeUnmount(() => {
  cleanup()
  status.value = 'idle'
})
</script>

<style scoped>
.gltf-viewer-3d {
  position: relative;
  border-radius: 6px;
  overflow: hidden;
  background: var(--p-surface-100, #f1f5f9);
}
.gltf-viewer-3d canvas {
  display: block;
  width: 100%;
  height: 100%;
  border-radius: 6px;
  vertical-align: middle;
}
.gltf-viewer-3d__overlay {
  position: absolute;
  inset: 0;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.25rem;
  color: var(--p-text-muted-color);
  pointer-events: none;
  border-radius: 6px;
  background: color-mix(in srgb, var(--p-surface-100, #f1f5f9) 85%, transparent);
}
.gltf-viewer-3d__error-overlay {
  position: absolute;
  inset: 0;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem;
  font-size: 0.875rem;
  text-align: center;
  border-radius: 6px;
  background: color-mix(in srgb, var(--p-surface-100, #f1f5f9) 92%, transparent);
}
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
.m-0 { margin: 0; }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
</style>
