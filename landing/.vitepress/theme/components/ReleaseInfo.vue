<template>
  <div class="release-info">
    <div v-if="loading" class="loading">Loading release information...</div>
    <div v-else-if="error" class="error">{{ error }}</div>
    <div v-else-if="release">
      <h3>📦 {{ release.name }}</h3>
      <div class="release-meta">
        <span>Version: <strong>{{ release.tag_name }}</strong></span>
        <span>Released: <strong>{{ formatDate(release.published_at) }}</strong></span>
      </div>
      <div class="release-changelog">
        <h4>What's New</h4>
        <div v-html="parseMarkdown(release.body)"></div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Octokit } from '@octokit/rest'

interface Release {
  tag_name: string
  name: string
  body: string
  published_at: string
}

const loading = ref(true)
const error = ref('')
const release = ref<Release | null>(null)

const octokit = new Octokit()

onMounted(async () => {
  try {
    const { data } = await octokit.repos.getLatestRelease({
      owner: 'Khesir',
      repo: 'KeepTrack'
    })

    release.value = {
      tag_name: data.tag_name,
      name: data.name || data.tag_name,
      body: data.body || 'No release notes available.',
      published_at: data.published_at ?? new Date().toISOString()
    }

    loading.value = false
  } catch (e: any) {
    error.value = e.message || 'Failed to fetch release information'
    loading.value = false
  }
})

function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

function parseMarkdown(markdown: string): string {
  // Basic markdown parsing
  return markdown
    // Convert headers
    .replace(/^### (.*$)/gim, '<h4>$1</h4>')
    .replace(/^## (.*$)/gim, '<h3>$1</h3>')
    .replace(/^# (.*$)/gim, '<h3>$1</h3>')
    // Convert bold
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    // Convert lists
    .replace(/^\* (.+)$/gim, '<li>$1</li>')
    .replace(/^- (.+)$/gim, '<li>$1</li>')
    // Wrap lists
    .replace(/(<li>.*<\/li>)/s, (match) => {
      return '<ul>' + match + '</ul>'
    })
    // Convert line breaks
    .replace(/\n/g, '<br>')
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
</style>
