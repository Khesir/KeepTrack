'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState } from 'react';
import ThemeToggle from './ThemeToggle';

const NAV_LINKS = [
  { label: 'Overview', href: '/' },
  { label: 'Changelog', href: '/changelog' },
  { label: 'Download', href: '/download' },
];

export default function Navbar() {
  const [menuOpen, setMenuOpen] = useState(false);
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-50 bg-ink/88 backdrop-blur-md border-b border-line/12">
      <div className="max-w-5xl mx-auto px-6 sm:px-10 h-16 flex items-center justify-between">
        <Link href="/" className="font-semibold text-[15px] tracking-tight text-paper">
          Keep Track
        </Link>

        <nav className="hidden md:flex items-center gap-7">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className={`text-sm transition-colors ${
                pathname === link.href
                  ? 'font-semibold text-paper'
                  : 'font-medium text-mist hover:text-paper'
              }`}
            >
              {link.label}
            </Link>
          ))}
          <a
            href="https://github.com/Khesir/KeepTrack"
            target="_blank"
            rel="noopener noreferrer"
            className="font-mono-nums text-[12.5px] text-mist hover:text-paper transition-colors"
          >
            GitHub &#8599;
          </a>
          <ThemeToggle />
        </nav>

        <div className="flex md:hidden items-center gap-1">
          <ThemeToggle />
          <button
            className="p-2 text-paper"
            onClick={() => setMenuOpen(!menuOpen)}
            aria-label="Toggle menu"
          >
            <div className="w-5 h-4 flex flex-col justify-between">
              <span className={`block h-0.5 bg-current transition-all ${menuOpen ? 'rotate-45 translate-y-1.5' : ''}`} />
              <span className={`block h-0.5 bg-current transition-all ${menuOpen ? 'opacity-0' : ''}`} />
              <span className={`block h-0.5 bg-current transition-all ${menuOpen ? '-rotate-45 -translate-y-1.5' : ''}`} />
            </div>
          </button>
        </div>
      </div>

      {menuOpen && (
        <div className="md:hidden bg-ink border-b border-line/12">
          <div className="max-w-5xl mx-auto px-6 py-4 flex flex-col gap-1">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setMenuOpen(false)}
                className="px-4 py-2.5 text-sm font-medium text-mist hover:text-paper hover:bg-line/5 rounded-lg transition-colors"
              >
                {link.label}
              </Link>
            ))}
            <a
              href="https://github.com/Khesir/KeepTrack"
              target="_blank"
              rel="noopener noreferrer"
              onClick={() => setMenuOpen(false)}
              className="px-4 py-2.5 font-mono-nums text-[12.5px] text-mist hover:text-paper hover:bg-line/5 rounded-lg transition-colors"
            >
              GitHub &#8599;
            </a>
          </div>
        </div>
      )}
    </header>
  );
}
