import type { Config } from 'tailwindcss';

function withAlpha(variable: string) {
  return `rgb(var(${variable}) / <alpha-value>)`;
}

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        ink: withAlpha('--color-ink'),
        card: withAlpha('--color-card'),
        'card-2': withAlpha('--color-card-2'),
        paper: withAlpha('--color-paper'),
        mist: withAlpha('--color-mist'),
        fog: withAlpha('--color-fog'),
        note: withAlpha('--color-note'),
        mint: withAlpha('--color-mint'),
        'mint-light': withAlpha('--color-mint-light'),
        lavender: withAlpha('--color-lavender'),
        coral: withAlpha('--color-coral'),
        line: withAlpha('--color-line'),
      },
      fontFamily: {
        sans: ['DM Sans', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [],
};

export default config;
