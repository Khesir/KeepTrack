import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Keep Track',
  description: 'Your personal finance manager - budgets, accounts, debts, and more',
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
            { text: 'Finance Overview', link: '/docs/features/finance' },
            { text: 'Budgets', link: '/docs/features/budgets' },
            { text: 'Accounts', link: '/docs/features/accounts' },
            { text: 'Transactions', link: '/docs/features/transactions' },
            { text: 'Debts & Receivables', link: '/docs/features/debts' },
            { text: 'Goals', link: '/docs/features/goals' },
            { text: 'Planned Payments', link: '/docs/features/planned-payments' }
          ]
        },
        {
          text: 'Guide',
          items: [
            { text: 'Themes', link: '/docs/guide/themes' }
          ]
        },
        {
          text: 'Updates',
          items: [
            { text: 'Changelog', link: '/docs/changelog' }
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
