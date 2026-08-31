import { NextRequest, NextResponse } from 'next/server';
import '@/lib/lemonsqueezy';
import { listSubscriptions } from '@lemonsqueezy/lemonsqueezy.js';

export async function POST(req: NextRequest) {
  try {
    const { email } = await req.json();
    if (!email?.trim()) {
      return NextResponse.json({ error: 'Email is required.' }, { status: 400 });
    }

    const origin = req.headers.get('origin') ?? process.env.NEXT_PUBLIC_APP_URL;

    const subs = await listSubscriptions({
      filter: { userEmail: email.trim() },
    });

    const active = subs.data?.data.find(
      (s) => s.attributes.status === 'active',
    );

    if (active) {
      return NextResponse.json({
        url: active.attributes.urls.customer_portal,
        subscribed: true,
      });
    }

    return NextResponse.json({
      url: `${origin}/pricing#checkout`,
      subscribed: false,
    });
  } catch (err: any) {
    console.error('[manage-subscription]', err);
    return NextResponse.json({ error: err.message ?? 'Request failed.' }, { status: 500 });
  }
}
