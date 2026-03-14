import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  root: 'src/client',
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      }
    }
  },
  build: {
    // SPA only; tsc writes dist/server (avoid emptyOutDir wiping it).
    outDir: '../../dist/public',
    emptyOutDir: true,
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src/client'),
      '@shared': resolve(__dirname, 'src/shared')
    }
  }
})