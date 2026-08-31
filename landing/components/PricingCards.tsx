import Link from 'next/link';
import { CheckIcon } from './Icons';

const FREE_FEATURES = [
  'Full monthly budgeting',
  'Savings wallets & goals',
  'Debt & receivables tracking',
  'Planned payments',
  'Subscription tracking',
  'Budget profiles',
  'Local backup & restore',
  'All platforms (offline)',
  'Light & dark mode',
];

const PLUS_FEATURES = [
  'Everything in Free',
  'Cloud sync across devices',
  'AI receipt scanner',
  'AI image upload',
  'AI monthly analytics',
  'Priority support',
];

function Check({ plus = false }: { plus?: boolean }) {
  return <CheckIcon className={`w-4 h-4 flex-shrink-0 ${plus ? 'text-lavender' : 'text-mint'}`} />;
}

export default function PricingCards() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-5 max-w-3xl mx-auto">
      <div className="bg-card border border-line/10 rounded-2xl p-8 flex flex-col">
        <div className="mb-6">
          <p className="font-mono-nums text-xs tracking-widest uppercase text-mist mb-3">Free</p>
          <div className="flex items-baseline gap-1 mb-1">
            <span className="text-4xl font-semibold text-paper font-mono-nums">&#8369;0</span>
            <span className="text-mist text-sm">/mo</span>
          </div>
          <p className="text-mist text-sm">Forever free. No card needed.</p>
        </div>

        <ul className="flex flex-col gap-3 flex-1 mb-8">
          {FREE_FEATURES.map((f) => (
            <li key={f} className="flex items-start gap-2.5 text-sm text-paper">
              <Check />
              <span>{f}</span>
            </li>
          ))}
        </ul>

        <Link
          href="/download"
          className="block text-center px-6 py-3 border border-line/12 text-paper font-semibold text-sm rounded-xl hover:bg-line/8 transition-colors duration-200"
        >
          Download Free
        </Link>
      </div>

      <div className="bg-card-2 rounded-2xl p-8 flex flex-col border border-line/10">
        <div className="mb-6">
          <div className="flex items-center justify-between mb-3">
            <p className="font-mono-nums text-xs tracking-widest uppercase text-lavender">Plus</p>
            <span className="text-xs font-semibold bg-lavender/15 text-lavender border border-lavender/30 px-2.5 py-1 rounded-full">
              Most Popular
            </span>
          </div>
          <div className="flex items-baseline gap-1 mb-1">
            <span className="text-4xl font-semibold text-paper font-mono-nums">&#8369;99</span>
            <span className="text-mist text-sm">/mo</span>
          </div>
          <p className="text-mist text-sm">Cancel anytime. No lock-in.</p>
        </div>

        <ul className="flex flex-col gap-3 flex-1 mb-8">
          {PLUS_FEATURES.map((f) => (
            <li key={f} className="flex items-start gap-2.5 text-sm text-note">
              <Check plus />
              <span>{f}</span>
            </li>
          ))}
        </ul>

        <span className="block text-center px-6 py-3 bg-lavender/15 text-lavender/60 font-semibold text-sm rounded-xl cursor-not-allowed select-none">
          Coming Soon
        </span>
      </div>
    </div>
  );
}
