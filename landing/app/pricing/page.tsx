'use client';

import { useState } from 'react';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import PricingCards from '@/components/PricingCards';

export default function PricingPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleCheckout = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) { setError('Email is required.'); return; }
    setError('');
    setLoading(true);
    try {
      const res = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Something went wrong.');
      window.location.href = data.url;
    } catch (err: any) {
      setError(err.message ?? 'Failed to start checkout.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Navbar />

      <main className="min-h-screen bg-ink pt-24 sm:pt-28 pb-24 px-6">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <p className="font-mono-nums text-xs tracking-widest uppercase text-lavender mb-3">Pricing</p>
            <h1 className="text-4xl sm:text-5xl font-semibold text-paper tracking-tight mb-4 text-balance">
              Simple, transparent pricing
            </h1>
            <p className="text-mist text-lg max-w-md mx-auto">
              Start free. No card required. Upgrade anytime.
            </p>
          </div>

          <PricingCards />

          <div id="checkout" className="mt-20 max-w-md mx-auto">
            <div className="bg-card border border-line/10 rounded-2xl p-8">
              <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-lavender/15 border border-lavender/30 rounded-full text-lavender text-xs font-semibold mb-5">
                Keep Track Plus
              </div>
              <h2 className="text-xl font-semibold text-paper mb-2">Keep Track Plus</h2>
              <p className="text-mist text-sm mb-6 leading-relaxed">
                Plus is coming soon. Cloud sync, AI features, and more — stay tuned.
              </p>

              <div className="px-6 py-4 bg-line/5 border border-line/10 rounded-xl text-center">
                <span className="text-mist text-sm font-medium">Coming Soon</span>
              </div>
            </div>
          </div>

          <div className="mt-16 max-w-2xl mx-auto">
            <h3 className="text-lg font-semibold text-paper mb-6 text-center">Frequently asked questions</h3>
            <div className="flex flex-col gap-4">
              {[
                {
                  q: 'Can I use the app without a subscription?',
                  a: 'Yes. The free tier is fully featured and works completely offline. You only need Plus if you want cloud sync or AI features.',
                },
                {
                  q: 'What happens to my data if I cancel Plus?',
                  a: 'Your data is always stored locally on your device. Cancelling Plus just turns off cloud sync — you keep everything.',
                },
                {
                  q: 'Which email should I use?',
                  a: 'Use the same email you signed in with on the Keep Track app. This links your subscription to your account.',
                },
                {
                  q: 'Is this a one-time payment?',
                  a: 'No — Plus is a monthly subscription at ₱99/mo. You can cancel anytime from your Stripe billing portal.',
                },
              ].map((item) => (
                <div key={item.q} className="bg-card border border-line/10 rounded-xl p-6">
                  <p className="font-semibold text-paper text-sm mb-2">{item.q}</p>
                  <p className="text-mist text-sm leading-relaxed">{item.a}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </main>

      <Footer />
    </>
  );
}
