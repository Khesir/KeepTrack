import Link from 'next/link';
import { KofiIcon } from './Icons';

const LINKS = [
  { label: 'Changelog', href: '/changelog' },
  { label: 'Download', href: '/download' },
  { label: 'Pricing', href: '/pricing' },
  { label: 'Support', href: '/support' },
];

export default function Footer() {
  return (
    <footer className="bg-ink border-t border-line/12">
      <div className="max-w-5xl mx-auto px-6 sm:px-10 py-12">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-8">
          <div>
            <span className="font-semibold text-paper text-sm block mb-3">Keep Track</span>
            <p className="font-mono-nums text-fog text-xs max-w-xs leading-relaxed">
              keep-track.khesir.com
            </p>
          </div>

          <div className="flex flex-col gap-4">
            <nav className="flex flex-wrap gap-x-6 gap-y-2">
              {LINKS.map((l) => (
                <Link
                  key={l.href}
                  href={l.href}
                  className="text-mist text-sm hover:text-paper transition-colors"
                >
                  {l.label}
                </Link>
              ))}
              <a
                href="https://github.com/Khesir/KeepTrack"
                target="_blank"
                rel="noopener noreferrer"
                className="text-mist text-sm hover:text-paper transition-colors"
              >
                GitHub
              </a>
            </nav>
            <a
              href="https://ko-fi.com/khesirr"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 px-4 py-2 bg-coral/15 border border-coral/25 rounded-xl text-coral text-sm font-medium hover:bg-coral/25 hover:border-coral/40 transition-all duration-200 w-fit"
            >
              <KofiIcon className="w-4 h-4" />
              Support on Ko-fi
            </a>
          </div>
        </div>

        <div className="mt-10 pt-6 border-t border-line/12 flex flex-col sm:flex-row items-center justify-between gap-3">
          <p className="text-fog text-xs">
            &copy; {new Date().getFullYear()} Keep Track. All rights reserved.
          </p>
          <div className="flex gap-5">
            <Link href="/privacy" className="text-fog text-xs hover:text-mist transition-colors">
              Privacy
            </Link>
            <Link href="/terms" className="text-fog text-xs hover:text-mist transition-colors">
              Terms
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
