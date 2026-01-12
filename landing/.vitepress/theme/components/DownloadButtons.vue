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
        <span class="download-icon">{{ getIcon(asset.name) }}</span>
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
  if (filename.includes('windows') || filename.endsWith('.exe')) return '🪟'
  if (filename.includes('android') || filename.endsWith('.apk')) return '🤖'
  return '📦'
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
</style>
