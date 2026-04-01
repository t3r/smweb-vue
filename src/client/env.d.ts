/// <reference types="vite/client" />

/** Injected by vite.config.js at build time (see scripts/resolve-git-slug.mjs). */
declare const __FGS_GIT_SLUG__: string
/** Repo HTTPS origin from package.json repository (footer commit link). */
declare const __FGS_REPO_WEB_URL__: string

interface ImportMetaEnv {
  readonly VITE_API_URL?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<object, object, unknown>
  export default component
}
