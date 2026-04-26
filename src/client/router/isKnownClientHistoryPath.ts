import { defineComponent, h } from 'vue'
import { createMemoryHistory, createRouter } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { ROUTES_META } from './routesMeta'

/** Minimal stand-in so we can reuse vue-router’s matcher in Node (Vite config) without loading real views. */
const RouteProbeDummy = defineComponent({
  name: 'RouteProbeDummy',
  setup: () => () => h('div'),
})

let probeRouter: ReturnType<typeof createRouter> | null = null

function getProbeRouter(): ReturnType<typeof createRouter> {
  if (!probeRouter) {
    const routes: RouteRecordRaw[] = ROUTES_META.map((m) => ({
      path: m.path,
      name: m.name,
      component: RouteProbeDummy,
      meta: { title: m.title },
    }))
    probeRouter = createRouter({
      history: createMemoryHistory(),
      routes,
    })
  }
  return probeRouter
}

/** True if `pathname` matches a configured client route (same rules as the SPA router). */
export function isKnownClientHistoryPath(pathname: string): boolean {
  const raw = pathname.split('?')[0] || '/'
  const p = raw.replace(/\/+$/, '') || '/'
  const resolved = getProbeRouter().resolve({ path: p })
  return resolved.matched.length > 0
}
