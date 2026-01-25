<template>
  <div class="download-section">
    <div v-if="loading" class="loading">Loading release information...</div>
    <div v-else-if="error" class="error">{{ error }}</div>
    <div v-else class="download-buttons">
      <a
        v-for="asset in downloadAssets"
        :key="asset.name"
        :href="asset.url"
        class="download-btn primary"
        target="_blank"
        rel="noopener noreferrer"
      >
        <span class="download-icon" v-html="getIcon(asset.name)"></span>
        <span>{{ getLabel(asset.name) }}</span>
        <span class="size">{{ formatSize(asset.size) }}</span>
      </a>
    </div>
    <div v-if="release" class="release-version">
      Latest version: <strong>{{ release.tag_name }}</strong>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Octokit } from '@octokit/rest'

interface Asset {
  name: string
  url: string
  size: number
}

interface Release {
  tag_name: string
  name: string
  body: string
  published_at: string
  assets: Asset[]
}

const loading = ref(true)
const error = ref('')
const release = ref<Release | null>(null)
const downloadAssets = ref<Asset[]>([])

const octokit = new Octokit()

onMounted(async () => {
  try {
    // Update with your actual GitHub username and repo name
    const { data } = await octokit.repos.getLatestRelease({
      owner: 'Khesir',
      repo: 'KeepTrack'
    })

    release.value = {
      tag_name: data.tag_name,
      name: data.name || data.tag_name,
      body: data.body || '',
      published_at: data.published_at ?? new Date().toISOString(),
      assets: data.assets.map(asset => ({
        name: asset.name,
        url: asset.browser_download_url,
        size: asset.size
      }))
    }

    // Filter for main installers
    downloadAssets.value = release.value.assets.filter(asset =>
      asset.name.endsWith('.exe') ||
      asset.name.endsWith('.apk')
    )

    loading.value = false
  } catch (e: any) {
    error.value = e.message || 'Failed to fetch release information'
    loading.value = false
  }
})

function getIcon(filename: string): string {
  if (filename.includes('windows') || filename.endsWith('.exe')) {
    return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/></svg>'
  }
  if (filename.includes('android') || filename.endsWith('.apk')) {
    return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M17.523 15.341c-.5 0-.91-.41-.91-.91s.41-.91.91-.91.91.41.91.91-.41.91-.91.91m-11.046 0c-.5 0-.91-.41-.91-.91s.41-.91.91-.91.91.41.91.91-.41.91-.91.91m11.4-6.044l1.994-3.455a.416.416 0 00-.152-.567.416.416 0 00-.568.152L17.12 8.93c-1.54-.7-3.27-1.09-5.12-1.09s-3.58.39-5.12 1.09L4.85 5.427a.416.416 0 00-.568-.152.416.416 0 00-.152.567l1.994 3.455C2.64 11.185 0 14.613 0 18.545h24c0-3.932-2.64-7.36-6.123-9.248"/></svg>'
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M20 6h-8l-2-2H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2z"/></svg>'
}

function getLabel(filename: string): string {
  if (filename.includes('windows') || filename.endsWith('.exe')) return 'Download for Windows'
  if (filename.includes('android') || filename.endsWith('.apk')) return 'Download for Android'
  return filename
}

function formatSize(bytes: number): string {
  const mb = bytes / (1024 * 1024)
  return `${mb.toFixed(1)} MB`
}
</script>

<style scoped>
.loading, .error {
  text-align: center;
  padding: 24px;
  color: var(--vp-c-text-2);
}

.error {
  color: var(--vp-c-danger);
}

.release-version {
  margin-top: 16px;
  text-align: center;
  font-size: 14px;
  color: var(--vp-c-text-2);
}

.size {
  font-size: 12px;
  opacity: 0.8;
  font-weight: 400;
}

.download-icon {
  display: flex;
  align-items: center;
}

.download-icon :deep(svg) {
  width: 24px;
  height: 24px;
}
</style>
