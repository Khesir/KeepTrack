import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import { getChangelog } from '@/lib/github';

const GITHUB_RELEASES_URL = 'https://github.com/Khesir/KeepTrack/releases';

export default async function ChangelogPage() {
  const releases = await getChangelog();

  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-ink pb-24 px-6">
        <div className="max-w-2xl mx-auto pt-20 sm:pt-24">
          <div className="flex items-end justify-between gap-6 flex-wrap">
            <div>
              <p className="font-mono-nums text-[11px] tracking-[0.2em] uppercase text-mint mb-6">
                Changelog
              </p>
              <h1 className="text-4xl sm:text-5xl font-semibold text-paper tracking-tight leading-[1.06] max-w-lg text-balance">
                Every release, straight from GitHub.
              </h1>
            </div>
            <a
              href={GITHUB_RELEASES_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="font-mono-nums text-xs text-paper border border-line/12 rounded-xl px-4 py-2.5 hover:bg-line/8 transition-colors whitespace-nowrap"
            >
              releases &#8599;
            </a>
          </div>
          <p className="text-mist text-[15px] leading-relaxed max-w-md mt-5 mb-14">
            Windows installers and Android APKs are published per tag. Versions follow{' '}
            <span className="font-mono-nums text-sm">pubspec.yaml</span>.
          </p>

          <p className="font-mono-nums text-xs text-fog mb-4">// changelog</p>

          {releases.length === 0 ? (
            <div className="text-center py-20">
              <p className="text-mist text-sm">Couldn&apos;t load releases right now.</p>
            </div>
          ) : (
            <div className="flex flex-col gap-3.5">
              {releases.map((r) => (
                <div
                  key={r.tag}
                  className={`rounded-2xl border p-5 sm:p-6 ${
                    r.isLatest ? 'border-mint/55 bg-mint/5' : 'border-line/10 bg-card'
                  }`}
                >
                  <div className="flex items-center justify-between gap-4 flex-wrap">
                    <div className="flex items-center gap-2.5">
                      <span className="font-mono-nums text-[15px] font-semibold text-paper">
                        {r.tag}
                      </span>
                      {r.isLatest && (
                        <span className="font-mono-nums text-[10.5px] font-semibold text-ink bg-mint rounded-full px-2.5 py-0.5">
                          current
                        </span>
                      )}
                    </div>
                    <span className="font-mono-nums text-[11.5px] text-fog">{r.date}</span>
                  </div>

                  {r.notes.length > 0 && (
                    <>
                      <p className="font-mono-nums text-[13px] text-mist mt-3.5">Changes:</p>
                      <div className="flex flex-col gap-1.5 mt-3">
                        {r.notes.map((note, i) => (
                          <div
                            key={i}
                            className="flex items-start gap-2.5 font-mono-nums text-[13px] leading-relaxed text-note"
                          >
                            <span className="text-fog">&#9702;</span>
                            <span className="flex-1">{note}</span>
                          </div>
                        ))}
                      </div>
                    </>
                  )}

                  {r.footnote && (
                    <p className="font-mono-nums text-xs text-fog mt-4">{r.footnote}</p>
                  )}

                  {r.compareUrl && (
                    <p className="font-mono-nums text-[13px] mt-3">
                      <span className="font-semibold text-paper">Full Changelog: </span>
                      <a
                        href={r.compareUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-lavender hover:text-paper transition-colors"
                      >
                        {r.compareLabel}
                      </a>
                    </p>
                  )}
                </div>
              ))}
            </div>
          )}

          <p className="font-mono-nums text-xs text-fog mt-6">
            synced from GitHub Releases &middot;{' '}
            <a
              href={GITHUB_RELEASES_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="text-lavender hover:text-paper transition-colors"
            >
              github.com/Khesir/KeepTrack/releases
            </a>
          </p>
        </div>
      </main>
      <Footer />
    </>
  );
}
