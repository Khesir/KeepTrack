import Link from 'next/link';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import { KofiIcon } from '@/components/Icons';
import { getLatestRelease } from '@/lib/github';

const FEATURES = [
  { no: '01', title: 'Zero-based budgets', body: 'Monthly budget profiles — assign every peso of income before the month starts.' },
  { no: '02', title: 'Transactions', body: 'Inflow and outflow against the budget, with category breakdown and photo attachments.' },
  { no: '03', title: 'Savings buckets', body: 'Named buckets with contribution tracking — emergency, travel, gadgets.' },
  { no: '04', title: 'Goals', body: 'Targets and deadlines, with progress against your monthly contributions.' },
  { no: '05', title: 'Debts & receivables', body: 'Payoff schedules for what you owe, and a record of what is owed to you.' },
  { no: '06', title: 'Planned payments', body: 'Recurring bills and subscriptions with next billing dates.' },
  { no: '07', title: 'Offline-first', body: 'Hive is the local source of truth; the backend reconciles when you come online.' },
  { no: '08', title: 'Backup & restore', body: 'Encrypted, password-protected cloud backup. Multi-currency, dark and light themes.' },
];

const PLATFORMS = [
  { name: 'Windows (x64)', note: 'Windows 10+ · Inno Setup installer', status: 'Available', ok: true },
  { name: 'Android (APK)', note: 'Android 8.0 and above', status: 'Available', ok: true },
  { name: 'macOS · Linux', note: 'Builds, not actively tested', status: 'Unofficial', ok: false },
  { name: 'Web · iOS', note: 'Chrome dev only · iOS not configured', status: 'Not shipped', ok: false },
];

export default async function HomePage() {
  const latest = await getLatestRelease();
  const version = latest?.version ?? '0.8.5';

  return (
    <>
      <Navbar />
      <main className="bg-ink">
        <section className="max-w-3xl mx-auto px-6 sm:px-10 pt-24 sm:pt-28">
          <p className="font-mono-nums text-[11px] tracking-[0.2em] uppercase text-lavender mb-6">
            Personal finance &middot; offline-first
          </p>
          <h1 className="text-5xl sm:text-6xl font-semibold leading-[1.05] tracking-tight text-paper mb-5 max-w-2xl text-balance">
            Keep your own books, month by month.
          </h1>
          <p className="text-lg sm:text-xl leading-relaxed text-mist max-w-xl mb-8">
            Zero-based budgeting, savings buckets, debts and planned payments — stored on your
            device first, synced when you want it. Windows and Android.
          </p>
          <div className="flex flex-wrap items-center gap-3">
            <Link
              href="/download"
              className="text-sm font-semibold text-ink bg-mint rounded-xl px-6 py-3.5 hover:bg-mint-light transition-colors"
            >
              Download for free
            </Link>
            <Link
              href="/changelog"
              className="font-mono-nums text-[13px] text-paper border border-line/12 rounded-xl px-5 py-3.5 hover:bg-line/8 transition-colors"
            >
              v{version} &mdash; what&apos;s new
            </Link>
          </div>
          <div className="flex flex-wrap gap-6 mt-12 pt-5 border-t border-line/12 font-mono-nums text-xs text-mist">
            <span>Flutter 3.35</span>
            <span>Apache 2.0</span>
            <span>Hive local store</span>
            <span>&#8369;0 forever</span>
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-6 sm:px-10 pt-20 sm:pt-24">
          <div className="flex items-baseline gap-3.5 mb-7">
            <span className="font-mono-nums text-xs text-lavender">01</span>
            <h2 className="text-xl font-semibold tracking-tight text-paper">What it does</h2>
            <span className="flex-1 h-px bg-line/12" />
          </div>
          <div className="grid sm:grid-cols-2">
            {FEATURES.map((f) => (
              <div key={f.no} className="pr-6 pt-5 pb-6 border-t border-line/7">
                <div className="flex items-baseline gap-3 mb-2">
                  <span className="font-mono-nums text-[11.5px] text-fog">{f.no}</span>
                  <span className="text-[15px] font-semibold text-paper">{f.title}</span>
                </div>
                <p className="text-sm leading-relaxed text-mist pl-7">{f.body}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-6 sm:px-10 pt-20">
          <div className="flex items-baseline gap-3.5 mb-7">
            <span className="font-mono-nums text-xs text-lavender">02</span>
            <h2 className="text-xl font-semibold tracking-tight text-paper">Platforms</h2>
            <span className="flex-1 h-px bg-line/12" />
          </div>
          <div>
            {PLATFORMS.map((p) => (
              <div
                key={p.name}
                className="grid grid-cols-[1fr_auto] sm:grid-cols-[200px_1fr_auto] gap-3 sm:gap-5 items-baseline py-4 border-t border-line/7"
              >
                <span className="text-[14.5px] font-semibold text-paper">{p.name}</span>
                <span className="hidden sm:block text-[13.5px] text-mist">{p.note}</span>
                <span
                  className={`font-mono-nums text-[11px] rounded-full px-2.5 py-1 whitespace-nowrap justify-self-end sm:justify-self-auto ${
                    p.ok
                      ? 'text-mint bg-mint/10 border border-mint/25'
                      : 'text-mist bg-card-2 border border-line/12'
                  }`}
                >
                  {p.status}
                </span>
              </div>
            ))}
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-6 sm:px-10 pt-20">
          <div className="flex items-baseline gap-3.5 mb-7">
            <span className="font-mono-nums text-xs text-lavender">03</span>
            <h2 className="text-xl font-semibold tracking-tight text-paper">Support the dev</h2>
            <span className="flex-1 h-px bg-line/12" />
          </div>
          <div className="grid sm:grid-cols-[0.9fr_1.1fr] gap-8 sm:gap-11 items-center">
            <div>
              <p className="text-[26px] font-semibold tracking-tight leading-tight text-paper">
                Keep Track is free, and <span className="text-mint">stays free.</span>
              </p>
              <p className="text-[13.5px] leading-relaxed text-mist mt-3">
                Nothing is locked behind a paywall. If the app helps you run your month, you can
                chip in to the developer.
              </p>
            </div>
            <div className="flex flex-col gap-3">
              <a
                href="https://ko-fi.com/khesirr"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-4 border border-line/10 rounded-2xl bg-card px-5 py-[18px] hover:border-mint/40 transition-colors"
              >
                <span className="w-11 h-11 rounded-[13px] bg-coral flex items-center justify-center flex-shrink-0 text-xl">
                  <KofiIcon className="w-5 h-5 text-ink" />
                </span>
                <span className="flex-1">
                  <span className="block font-sans text-base font-semibold text-paper">Ko-fi</span>
                  <span className="block font-mono-nums text-xs text-mist mt-1">
                    one-off coffee &middot; ko-fi.com/khesirr
                  </span>
                </span>
                <span className="text-fog text-lg">&rarr;</span>
              </a>
              <p className="font-mono-nums text-[11.5px] text-fog text-center mt-0.5">
                100% &rarr; Keep Track development &amp; maintenance
              </p>
            </div>
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-6 sm:px-10 pt-20 pb-24">
          <div className="border-t border-line/12 pt-11 flex flex-wrap items-end justify-between gap-8">
            <div>
              <h2 className="text-[34px] font-semibold tracking-tight text-paper mb-2.5">
                Start with this month.
              </h2>
              <p className="text-mist text-[15px]">Install, set your income, and the ledger is yours.</p>
            </div>
            <div className="flex gap-3">
              <Link
                href="/download"
                className="text-sm font-semibold text-ink bg-mint rounded-xl px-6 py-3.5 hover:bg-mint-light transition-colors"
              >
                Download v{version}
              </Link>
              <a
                href="https://github.com/Khesir/KeepTrack"
                target="_blank"
                rel="noopener noreferrer"
                className="font-mono-nums text-[13px] text-paper border border-line/12 rounded-xl px-5 py-3.5 hover:bg-line/8 transition-colors"
              >
                Source &#8599;
              </a>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
