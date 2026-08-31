import { NextRequest, NextResponse } from 'next/server';
import '@/lib/lemonsqueezy';
import { createCheckout } from '@lemonsqueezy/lemonsqueezy.js';

export async function POST(req: NextRequest) {
  try {
    const { email } = await req.json();
    if (!email?.trim()) {
      return NextResponse.json({ error: 'Email is required.' }, { status: 400 });
    }

    const origin = req.headers.get('origin') ?? process.env.NEXT_PUBLIC_APP_URL;

    const checkout = await createCheckout(
      process.env.LEMONSQUEEZY_STORE_ID!,
      process.env.LEMONSQUEEZY_VARIANT_ID!,
      {
        checkoutData: {
          email: email.trim(),
          custom: { user_email: email.trim() },
        },
        productOptions: {
          redirectUrl: `${origin}/success`,
        },
      },
    );

    const url = checkout.data?.data.attributes.url;
    if (!url) throw new Error('Failed to create checkout session.');

    return NextResponse.json({ url });
  } catch (err: any) {
    console.error('[checkout]', err);
    return NextResponse.json({ error: err.message ?? 'Checkout failed.' }, { status: 500 });
  }
}
