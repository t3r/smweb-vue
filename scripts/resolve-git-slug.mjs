/**
 * Used by Vite at build time. Priority:
 * 1. VITE_APP_GIT_SLUG or GIT_SLUG
 * 2. VERSION file at repo root (written by deploy before `npm run build`)
 * 3. git rev-parse --short HEAD
 * 4. "dev"
 */
import { readFileSync, existsSync } from 'node:fs'
import { execSync } from 'node:child_process'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')

export function resolveGitSlug() {
  const fromEnv = process.env.VITE_APP_GIT_SLUG?.trim() || process.env.GIT_SLUG?.trim()
  if (fromEnv) return fromEnv

  const versionFile = resolve(root, 'VERSION')
  if (existsSync(versionFile)) {
    const v = readFileSync(versionFile, 'utf8').trim().split(/\r?\n/)[0]?.trim()
    if (v) return v
  }

  try {
    return execSync('git rev-parse --short HEAD', { encoding: 'utf8', cwd: root }).trim()
  } catch {
    return 'dev'
  }
}
