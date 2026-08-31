import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import { getLatestRelease } from '@/lib/github';

const RELEASES_URL = 'https://github.com/Khesir/KeepTrack/releases';
const LATEST_URL = 'https://github.com/Khesir/KeepTrack/releases/latest';

const WIN_STEPS = [
  'Run the installer. Windows may warn about an unknown publisher — choose More info → Run anyway.',
  'Keep Track installs per-user; no admin rights needed.',
  'Launch and set your first monthly budget. Everything is stored locally until you sign in.',
];

const ANDROID_STEPS = [
  'Download the APK and open it from your notifications.',
  'Allow installs from this source when Android asks.',
  'Open the app — or try Demo mode from Settings to explore with sample data.',
];

export default async function DownloadPage() {
  const latest = await getLatestRelease();
  const version = latest?.version ?? '0.8.5';

  const assets = [
    {
      platform: 'Windows',
      requirement: 'Windows 10 or later · x64',
      file: `KeepTrack-v${version}.exe`,
      meta: 'Inno Setup installer',
      cta: 'Download .exe',
      href: latest?.windowsUrl ?? LATEST_URL,
    },
    {
      platform: 'Android',
      requirement: 'Android 8.0 and above',
      file: `KeepTrack-v${version}.apk`,
      meta: 'Sideload APK · not on Play Store yet',
      cta: 'Download .apk',
      href: latest?.androidUrl ?? LATEST_URL,
    },
  ];

  return (
    <>
      <Navbar />
      <main className="bg-ink min-h-screen pb-24">
        <section className="max-w-3xl mx-auto px-6 sm:px-10 pt-24 sm:pt-28">
          <p className="font-mono-nums text-[11px] tracking-[0.2em] uppercase text-lavender mb-6">
            Download
          </p>
          <div className="flex items-end justify-between gap-6 flex-wrap">
            <h1 className="text-4xl sm:text-5xl font-semibold leading-[1.05] tracking-tight text-paper max-w-lg text-balance">
              Latest build, straight from the release.
            </h1>
            <div className="text-right font-mono-nums text-xs text-mist leading-[1.9]">
              <div className="text-[15px] text-paper">v{version}</div>
              {latest?.date && <div>{latest.date}</div>}
              <div className="text-fog">tag {latest?.tag ?? `v${version}`}</div>
            </div>
          </div>
          <p className="text-base leading-relaxed text-mist max-w-lg mt-5">
            Free, no account required. The app runs fully offline — sign in only if you want
            cloud backup.
          </p>
        </section>

        <section className="max-w-3xl mx-auto px-6 sm:px-10 pt-12">
          {assets.map((a) => (
            <div
              key={a.platform}
              className="grid sm:grid-cols-[1fr_auto] gap-4 sm:gap-6 items-center py-6 border-t border-line/12"
            >
              <div>
                <div className="flex items-baseline gap-3 flex-wrap">
                  <span className="text-xl font-semibold tracking-tight text-paper">{a.platform}</span>
                  <span className="font-mono-nums text-xs text-mist">{a.requirement}</span>
                </div>
                <div className="font-mono-nums text-[12.5px] text-mist mt-2">{a.file}</div>
                <div className="font-mono-nums text-[11.5px] text-fog mt-1">{a.meta}</div>
              </div>
              <a
                href={a.href}
                className="text-sm font-semibold text-ink bg-mint rounded-xl px-6 py-3.5 hover:bg-mint-light transition-colors whitespace-nowrap text-center"
              >
                {a.cta}
              </a>
            </div>
          ))}
          <div className="grid sm:grid-cols-[1fr_auto] gap-4 sm:gap-6 items-center py-5 border-t border-b border-line/12">
            <div>
              <div className="text-[15px] font-semibold text-paper">macOS &middot; Linux</div>
              <p className="text-[13.5px] text-mist mt-1.5">
                The project builds on both, but neither is actively tested or packaged. Build
                from source if you want to try it.
              </p>
            </div>
            <a
              href="https://github.com/Khesir/KeepTrack"
              target="_blank"
              rel="noopener noreferrer"
              className="font-mono-nums text-[13px] text-paper border border-line/12 rounded-xl px-[18px] py-3 hover:bg-line/8 transition-colors whitespace-nowrap text-center"
            >
              build from source &#8599;
            </a>
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-6 sm:px-10 pt-[72px]">
          <div className="flex items-baseline gap-3.5 mb-[26px]">
            <span className="font-mono-nums text-xs text-lavender">01</span>
            <h2 className="text-xl font-semibold tracking-tight text-paper">Installing</h2>
            <span className="flex-1 h-px bg-line/12" />
          </div>
          <div className="grid sm:grid-cols-2 gap-11">
            <div>
              <p className="font-mono-nums text-[11.5px] tracking-[0.14em] uppercase text-mist mb-4">
                Windows
              </p>
              {WIN_STEPS.map((step, i) => (
                <div key={i} className="flex gap-3.5 py-3.5 border-t border-line/7">
                  <span className="font-mono-nums text-xs text-fog w-4 flex-shrink-0">{i + 1}</span>
                  <span className="flex-1 text-sm leading-relaxed text-note">{step}</span>
                </div>
              ))}
            </div>
            <div>
              <p className="font-mono-nums text-[11.5px] tracking-[0.14em] uppercase text-mist mb-4">
                Android
              </p>
              {ANDROID_STEPS.map((step, i) => (
                <div key={i} className="flex gap-3.5 py-3.5 border-t border-line/7">
                  <span className="font-mono-nums text-xs text-fog w-4 flex-shrink-0">{i + 1}</span>
                  <span className="flex-1 text-sm leading-relaxed text-note">{step}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-6 sm:px-10 pt-[72px]">
          <div className="border-t border-line/12 pt-[26px] flex items-center justify-between gap-5 flex-wrap">
            <span className="font-mono-nums text-[12.5px] text-mist">
              Older versions live in the release history.
            </span>
            <span className="flex gap-5 font-mono-nums text-[12.5px]">
              <a href="/changelog" className="text-lavender hover:text-paper transition-colors">
                changelog
              </a>
              <a
                href={RELEASES_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="text-lavender hover:text-paper transition-colors"
              >
                all releases &#8599;
              </a>
            </span>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
