import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';

export default function TermsPage() {
  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-ink pt-24 sm:pt-28 pb-24 px-6">
        <div className="max-w-2xl mx-auto">
          <div className="mb-12">
            <p className="font-mono-nums text-xs tracking-widest uppercase text-lavender mb-3">Legal</p>
            <h1 className="text-4xl sm:text-5xl font-semibold text-paper tracking-tight mb-3">
              Terms of Service
            </h1>
            <p className="text-mist text-sm">Last updated: June 1, 2026</p>
          </div>

          <div className="flex flex-col gap-10 text-sm leading-relaxed">
            <Section title="Acceptance">
              By downloading, installing, or using Keep Track, you agree to these Terms of Service. If you do not agree, do not use the app.
            </Section>

            <Section title="The Service">
              Keep Track is a personal finance management application available on Windows and Android. The core app is free and works fully offline. Keep Track Plus is an optional paid subscription (₱99/month) that adds cloud sync and AI features.
            </Section>

            <Section title="Free Tier">
              <ul className="flex flex-col gap-2 list-none">
                <Li>The free tier is provided as-is, without any time limit or feature expiry.</Li>
                <Li>No account is required to use the free tier.</Li>
                <Li>All your data remains on your device. We have no access to it.</Li>
              </ul>
            </Section>

            <Section title="Keep Track Plus Subscription">
              <ul className="flex flex-col gap-2 list-none">
                <Li>Plus is billed at ₱99/month via Stripe. Billing recurs monthly until cancelled.</Li>
                <Li>You may cancel at any time. Cancellation takes effect at the end of the current billing period.</Li>
                <Li>No refunds are issued for partial billing periods.</Li>
                <Li>If payment fails, access to Plus features will be suspended until payment is resolved.</Li>
                <Li>We reserve the right to change the subscription price with 30 days' notice.</Li>
              </ul>
            </Section>

            <Section title="Acceptable Use">
              <p className="mb-3">You agree not to:</p>
              <ul className="flex flex-col gap-2 list-none">
                <Li>Reverse engineer, decompile, or modify the app.</Li>
                <Li>Use the app for any unlawful purpose.</Li>
                <Li>Attempt to gain unauthorized access to the backend or any related systems.</Li>
                <Li>Submit false or misleading support requests.</Li>
              </ul>
            </Section>

            <Section title="Your Data">
              All financial data lives on your device. We never receive or store it in readable form. When you use cloud sync (Plus), your app uploads a single encrypted file that only you can decrypt — we have no access to its contents and cannot recover it if you lose your password. You own your data entirely. We provide server infrastructure; nothing more. See our <a href="/privacy" className="text-lavender hover:text-paper transition-colors">Privacy Policy</a> for full details.
            </Section>

            <Section title="Availability">
              We aim for high availability but do not guarantee uninterrupted service. Cloud sync and AI features (Plus) depend on third-party infrastructure. The free tier (fully local) is unaffected by any backend downtime.
            </Section>

            <Section title="Disclaimer of Warranties">
              Keep Track is provided "as is" without warranties of any kind. We are not responsible for financial decisions made based on data within the app. Always verify important financial information independently.
            </Section>

            <Section title="Limitation of Liability">
              To the maximum extent permitted by law, Keep Track and its developer shall not be liable for any indirect, incidental, or consequential damages arising from your use of the app.
            </Section>

            <Section title="Changes to These Terms">
              We may update these terms from time to time. Continued use of Keep Track after changes constitutes acceptance of the updated terms. Material changes will be announced via the <a href="/changelog" className="text-lavender hover:text-paper transition-colors">changelog</a>.
            </Section>

            <Section title="Contact">
              Questions about these terms? Reach us via the <a href="/support" className="text-lavender hover:text-paper transition-colors">support page</a>.
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
