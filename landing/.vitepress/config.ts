import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Keep Track',
  description: 'Your all-in-one personal management system - Tasks, Finance, and more',
  base: '/',

  head: [
    ['link', { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#6366F1' }],
  ],

  themeConfig: {
    logo: '/logo.png',

    nav: [
      { text: 'Home', link: '/' },
      { text: 'Download', link: '/download' },
      { text: 'Docs', link: '/docs/' },
      { text: 'GitHub', link: 'https://github.com/Khesir/KeepTrack' }
    ],

    sidebar: {
      '/docs/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/docs/' },
            { text: 'Installation', link: '/docs/installation' },
            { text: 'Quick Start', link: '/docs/quickstart' }
          ]
        },
        {
          text: 'Features',
          items: [
            { text: 'Task Management', link: '/docs/features/tasks' },
            { text: 'Finance Tracking', link: '/docs/features/finance' },
            { text: 'Pomodoro Timer', link: '/docs/features/pomodoro' }
          ]
        },
        {
          text: 'Guide',
          items: [
            { text: 'Configuration', link: '/docs/guide/configuration' },
            { text: 'Themes', link: '/docs/guide/themes' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Khesir/KeepTrack' }
    ],

    footer: {
      message: 'Released under the Apache 2.0 License. ⚠️ Logo is a placeholder and will be updated later.',
      copyright: 'Copyright © 2025-present Keep-track'
    }
  }
})
