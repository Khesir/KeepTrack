'use client';

import { Suspense, useState } from 'react';
import { useSearchParams } from 'next/navigation';

function SubscriptionForm() {
  const searchParams = useSearchParams();
  const [email, setEmail] = useState(searchParams.get('email') ?? '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) { setError('Email is required.'); return; }
    setError('');
    setLoading(true);
    try {
      const res = await fetch('/api/manage-subscription', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Something went wrong.');
      window.location.href = data.url;
    } catch (err: any) {
      setError(err.message ?? 'Failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3">
      <div>
        <input
          type="email"
          placeholder="your@email.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full px-4 py-3 bg-line/8 border border-line/15 text-paper placeholder-mist/60 rounded-xl text-sm focus:outline-none focus:border-mint/60 focus:bg-line/10 transition-colors"
        />
        {error && <p className="text-coral text-xs mt-2">{error}</p>}
      </div>
      <button
        type="submit"
        disabled={loading}
        className="px-6 py-3 bg-mint text-ink font-semibold text-sm rounded-xl hover:bg-mint-light disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
      >
        {loading ? 'Loading…' : 'Continue →'}
      </button>
    </form>
  );
}

export default function SubscriptionPage() {
  return (
    <main
      className="min-h-screen bg-ink flex items-center justify-center px-6"
      style={{
        background:
          'radial-gradient(ellipse 80% 50% at 50% 0%, rgb(var(--color-mint) / 0.12) 0%, rgb(var(--color-ink)) 60%)',
      }}
    >
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <span className="font-semibold text-paper text-lg tracking-tight mb-5 block">Keep Track</span>
          <h1 className="text-xl font-semibold text-paper tracking-tight">Manage your subscription</h1>
          <p className="text-mist text-sm mt-2 leading-relaxed">
            Enter the email you use in Keep Track.<br />
            We'll look up your account and take you to the right place.
          </p>
        </div>

        <div className="bg-line/5 border border-line/10 rounded-2xl p-6">
          <Suspense fallback={null}>
            <SubscriptionForm />
          </Suspense>
          <p className="text-fog text-xs mt-4 text-center">
            Secured by Stripe · No account required here
          </p>
        </div>

        <p className="text-fog text-xs text-center mt-6">
          Not subscribed yet?{' '}
          <a href="/pricing" className="text-lavender hover:text-paper transition-colors underline underline-offset-2">
            See pricing
          </a>
        </p>
      </div>
    </main>
  );
}
