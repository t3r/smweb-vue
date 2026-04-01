/**
 * Runtime build id for the deployed app (same resolution order as scripts/resolve-git-slug.mjs).
 * Compared with the id baked into the client bundle to detect stale SPAs after deploy.
 */
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { execSync } from 'node:child_process'

function findPackageJsonRoot(startDir: string): string {
  let dir = path.resolve(startDir)
  const { root: fsRoot } = path.parse(dir)
  while (dir !== fsRoot) {
    if (fs.existsSync(path.join(dir, 'package.json'))) return dir
    dir = path.dirname(dir)
  }
  return process.cwd()
}

export function getClientBuildId(): string {
  const fromEnv = process.env.VITE_APP_GIT_SLUG?.trim() || process.env.GIT_SLUG?.trim()
  if (fromEnv) return fromEnv

  const root = findPackageJsonRoot(path.dirname(fileURLToPath(import.meta.url)))
  const versionFile = path.join(root, 'VERSION')
  if (fs.existsSync(versionFile)) {
    const v = fs.readFileSync(versionFile, 'utf8').trim().split(/\r?\n/)[0]?.trim()
    if (v) return v
  }

  try {
    return execSync('git rev-parse --short HEAD', { encoding: 'utf8', cwd: root }).trim()
  } catch {
    return 'dev'
  }
}
