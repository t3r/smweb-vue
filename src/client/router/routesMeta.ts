/**
 * Single source of truth for client history paths (order matters: static segments before `:id` params).
 * Wire components in `router/index.ts` via `routeComponents`.
 */
export const ROUTES_META = [
  { path: '/', name: 'Home', title: 'Home' },
  { path: '/news', name: 'News', title: 'News' },
  { path: '/about', name: 'About', title: 'About' },
  { path: '/models', name: 'Models', title: 'Models' },
  { path: '/models/add', name: 'AddModel', title: 'Add model' },
  { path: '/models/:id/edit', name: 'EditModel', title: 'Update model' },
  { path: '/models/:id', name: 'ModelDetail', title: 'Model' },
  { path: '/map', name: 'Map', title: 'Map' },
  { path: '/objects', name: 'Objects', title: 'Objects' },
  { path: '/objects/import', name: 'ObjectMassImport', title: 'Mass import objects' },
  { path: '/objects/:id', name: 'ObjectDetail', title: 'Object' },
  { path: '/authors', name: 'Authors', title: 'Authors' },
  { path: '/authors/:id', name: 'AuthorDetail', title: 'Author' },
  { path: '/position-requests', name: 'PositionRequests', title: 'Position requests' },
] as const

export type AppRouteName = (typeof ROUTES_META)[number]['name']
