import crypto from 'crypto';
import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

const BACKEND_URL = process.env.BACKEND_URL;
const WEBHOOK_SECRET = process.env.LEMONSQUEEZY_WEBHOOK_SECRET!;

async function notifyBackend(email: string, status: 'active' | 'cancelled') {
  if (!BACKEND_URL) return;
  await fetch(`${BACKEND_URL}/api/v1/users/internal/subscription`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-internal-secret': process.env.INTERNAL_SECRET ?? '',
    },
    body: JSON.stringify({ email, status }),
  });
}

export async function POST(req: NextRequest) {
  const rawBody = await req.text();
  const signature = req.headers.get('x-signature');

  if (!signature) {
    return NextResponse.json({ error: 'Missing signature.' }, { status: 400 });
  }

  const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET);
  const digest = hmac.update(rawBody).digest('hex');

  if (digest !== signature) {
    return NextResponse.json({ error: 'Invalid signature.' }, { status: 400 });
  }

  try {
    const event = JSON.parse(rawBody);
    const eventName: string = event.meta?.event_name;
    const email: string =
      event.meta?.custom_data?.user_email ?? event.data?.attributes?.user_email;

    if (!email) {
      console.warn('[webhook] No email found in event', eventName);
      return NextResponse.json({ received: true });
    }

    switch (eventName) {
      case 'subscription_created':
        await notifyBackend(email, 'active');
        break;
      case 'subscription_cancelled':
      case 'subscription_expired':
        await notifyBackend(email, 'cancelled');
        break;
    }
  } catch (err) {
    console.error('[webhook] handler error:', err);
  }

  return NextResponse.json({ received: true });
}
