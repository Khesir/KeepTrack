# Personal Codex Landing Page

This is the VitePress-powered landing page and documentation site for Personal Codex.

## Features

- 🎨 Modern landing page with hero section
- 📦 Automatic latest release detection via GitHub API (Octokit)
- 📥 Download buttons for all platforms
- 📝 Release changelog display
- 📚 Comprehensive documentation
- 🌙 Dark mode support
- 📱 Fully responsive design

## Prerequisites

- Node.js 18+ and npm/yarn/pnpm

## Setup

1. Install dependencies:
```bash
npm install
# or
yarn install
# or
pnpm install
```

2. Update GitHub repository info in:
   - `.vitepress/theme/components/DownloadButtons.vue` (line 51-52)
   - `.vitepress/theme/components/ReleaseInfo.vue` (line 29-30)
   - `.vitepress/config.ts` (GitHub links)

Replace `yourusername` with your actual GitHub username and `personal-codex` with your repository name.

## Development

Run the development server:

```bash
npm run dev
```

Visit `http://localhost:5173` to see your site.

## Build

Build for production:

```bash
npm run build
```

The built site will be in `.vitepress/dist/`.

## Preview

Preview the production build:

```bash
npm run preview
```

## Deployment

### GitHub Pages

1. Update `.vitepress/config.ts` with your base URL:
```ts
base: '/your-repo-name/'
```

2. Add GitHub Actions workflow (`.github/workflows/deploy.yml`):
```yaml
name: Deploy VitePress

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - name: Install dependencies
        run: cd landing && npm install
      - name: Build
        run: cd landing && npm run build
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: landing/.vitepress/dist
```

### Netlify

1. Connect your repository to Netlify
2. Set build settings:
   - **Base directory**: `landing`
   - **Build command**: `npm run build`
   - **Publish directory**: `landing/.vitepress/dist`

### Vercel

1. Import your repository to Vercel
2. Set root directory to `landing`
3. Framework preset: VitePress
4. Deploy!

## Customization

### Theme Colors

Edit `.vitepress/theme/custom.css` to change colors:

```css
:root {
  --vp-c-brand: #6366F1;
  --vp-c-brand-light: #818CF8;
  /* ... */
}
```

### Navigation

Edit `.vitepress/config.ts` to customize navigation and sidebar.

### Content

- Landing page: `index.md`
- Download page: `download.md`
- Documentation: `docs/` folder

## Structure

```
landing/
├── .vitepress/
│   ├── config.ts           # Site configuration
│   └── theme/
│       ├── index.ts        # Theme customization
│       ├── custom.css      # Custom styles
│       └── components/
│           ├── DownloadButtons.vue  # GitHub release downloads
│           └── ReleaseInfo.vue      # Release changelog
├── docs/                   # Documentation pages
│   ├── index.md
│   ├── installation.md
│   └── quickstart.md
├── index.md                # Landing page
├── download.md             # Download page
└── package.json
```

## License

MIT
