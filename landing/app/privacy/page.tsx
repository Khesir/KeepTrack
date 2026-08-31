import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';

export default function PrivacyPage() {
  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-ink pt-24 sm:pt-28 pb-24 px-6">
        <div className="max-w-2xl mx-auto">
          <div className="mb-12">
            <p className="font-mono-nums text-xs tracking-widest uppercase text-lavender mb-3">Legal</p>
            <h1 className="text-4xl sm:text-5xl font-semibold text-paper tracking-tight mb-3">
              Privacy Policy
            </h1>
            <p className="text-mist text-sm">Last updated: June 1, 2026</p>
          </div>

          <div className="flex flex-col gap-10 text-sm leading-relaxed text-paper">
            <Section title="Overview">
              Keep Track is a local-first personal finance app. Your financial data — transactions, budgets, debts, goals, and savings — lives entirely on your device. We never see it, store it, or have any access to it. Even with Keep Track Plus, we only store an opaque encrypted file on your behalf. We cannot open it, read it, or recover it under any circumstances.
            </Section>

            <Section title="What We Collect">
              <p className="mb-3">We collect only the minimum needed to operate accounts and subscriptions:</p>
              <ul className="flex flex-col gap-2 list-none">
                <Li>
                  <strong>Account identity</strong> — your name and email from Google Sign-In, used only to identify your account and link it to a subscription.
                </Li>
                <Li>
                  <strong>Subscription status</strong> — whether your account has an active Plus subscription. Processed by Stripe. We do not store card details.
                </Li>
                <Li>
                  <strong>Support messages</strong> — your name, email, and message when you contact us. Used solely to respond to your inquiry.
                </Li>
              </ul>
            </Section>

            <Section title="What We Do Not Collect">
              <ul className="flex flex-col gap-2 list-none">
                <Li>Your financial records of any kind — transactions, budgets, debts, savings, goals, or categories. None of this ever leaves your device in a readable form.</Li>
                <Li>The contents of your cloud backup. When you sync, we receive and store a single encrypted file. It is encrypted on your device with your password before upload. We have no key, no access, and no ability to recover it.</Li>
                <Li>Device identifiers, advertising IDs, or behavioral analytics.</Li>
                <Li>Any data from users on the free tier — there is no account, no server communication.</Li>
              </ul>
            </Section>

            <Section title="Cloud Sync (Plus)">
              Keep Track Plus gives you a server to link your devices together. When you sync, your app uploads a single encrypted file to our storage. That file is encrypted on your device using a password only you know — before it ever leaves your device. We store the file as an opaque blob. We cannot decrypt it, read it, or recover it if you lose your password. You own your data entirely. We are just the pipe.
            </Section>

            <Section title="How We Use What We Collect">
              <ul className="flex flex-col gap-2 list-none">
                <Li>To authenticate you and associate your account with a Plus subscription.</Li>
                <Li>To store your encrypted backup file so your devices can retrieve it.</Li>
                <Li>To respond to support requests.</Li>
                <Li>To manage billing via Stripe.</Li>
              </ul>
              <p className="mt-3">We do not sell, share, or use your data for any purpose beyond operating the service.</p>
            </Section>

            <Section title="Third-Party Services">
              <ul className="flex flex-col gap-2 list-none">
                <Li><strong>Google OAuth</strong> — used for sign-in. Subject to Google's Privacy Policy.</Li>
                <Li><strong>Stripe</strong> — used for payment processing. Subject to Stripe's Privacy Policy.</Li>
                <Li><strong>Vercel Blob</strong> — used to store encrypted cloud backups. Data is encrypted before upload.</Li>
              </ul>
            </Section>

            <Section title="Data Retention">
              <p>Account and subscription data is retained as long as your account exists. Your encrypted backup file is overwritten each time you sync — only one copy is ever stored. Support tickets are retained for up to 12 months. You may request deletion of your account and all associated data at any time via the <a href="/support" className="text-lavender hover:text-paper transition-colors">support page</a>.</p>
            </Section>

            <Section title="Your Rights">
              <p>You have the right to access, correct, or delete your personal data at any time. To exercise these rights, contact us via the <a href="/support" className="text-lavender hover:text-paper transition-colors">support page</a>.</p>
            </Section>

            <Section title="Contact">
              <p>Questions about this policy? Reach us via the <a href="/support" className="text-lavender hover:text-paper transition-colors">support page</a> or at Ko-fi: <a href="https://ko-fi.com/khesirr" target="_blank" rel="noopener noreferrer" className="text-lavender hover:text-paper transition-colors">ko-fi.com/khesirr</a>.</p>
            </Section>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h2 className="text-base font-semibold text-paper mb-3 flex items-center gap-3">
        {title}
        <span className="h-px flex-1 bg-line/10" />
      </h2>
      <div className="text-mist">{children}</div>
    </div>
  );
}

function Li({ children }: { children: React.ReactNode }) {
  return (
    <li className="flex items-start gap-2.5">
      <span className="w-1 h-1 rounded-full bg-mist mt-2 flex-shrink-0" />
      <span>{children}</span>
    </li>
  );
}
