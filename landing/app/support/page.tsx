'use client';

import { useRef, useState } from 'react';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';

const BACKEND = process.env.NEXT_PUBLIC_BACKEND_URL;
const MAX_IMAGES = 5;
const MAX_SIZE_MB = 5;

const TICKET_TYPES = [
  { value: 'bug', label: 'Bug Report', desc: 'Something is broken or not working as expected.' },
  { value: 'question', label: 'Question', desc: 'I need help understanding how something works.' },
  { value: 'feature', label: 'Feature Request', desc: 'I have an idea for something new.' },
  { value: 'other', label: 'Other', desc: 'Something else entirely.' },
];

type Field = 'name' | 'email' | 'subject' | 'message' | 'type';

type ImageFile = { file: File; preview: string };

export default function SupportPage() {
  const [form, setForm] = useState({ name: '', email: '', subject: '', message: '', type: 'bug' });
  const [errors, setErrors] = useState<Partial<Record<Field, string>>>({});
  const [images, setImages] = useState<ImageFile[]>([]);
  const [imageError, setImageError] = useState('');
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [serverError, setServerError] = useState('');
  const fileRef = useRef<HTMLInputElement>(null);

  const set = (field: Field, value: string) => {
    setForm((f) => ({ ...f, [field]: value }));
    setErrors((e) => ({ ...e, [field]: undefined }));
  };

  const addImages = (files: FileList | null) => {
    if (!files) return;
    setImageError('');
    const incoming = Array.from(files);
    const valid: ImageFile[] = [];
    for (const file of incoming) {
      if (!file.type.startsWith('image/')) { setImageError('Only image files are allowed.'); continue; }
      if (file.size > MAX_SIZE_MB * 1024 * 1024) { setImageError(`Max file size is ${MAX_SIZE_MB}MB.`); continue; }
      if (images.length + valid.length >= MAX_IMAGES) { setImageError(`Max ${MAX_IMAGES} images.`); break; }
      valid.push({ file, preview: URL.createObjectURL(file) });
    }
    setImages((prev) => [...prev, ...valid]);
  };

  const removeImage = (i: number) => {
    setImages((prev) => {
      URL.revokeObjectURL(prev[i].preview);
      return prev.filter((_, idx) => idx !== i);
    });
  };

  const validate = (): boolean => {
    const next: Partial<Record<Field, string>> = {};
    if (!form.name.trim()) next.name = 'Name is required.';
    if (!form.email.trim()) next.email = 'Email is required.';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) next.email = 'Enter a valid email.';
    if (!form.subject.trim()) next.subject = 'Subject is required.';
    if (!form.message.trim()) next.message = 'Message is required.';
    else if (form.message.trim().length < 20) next.message = 'Please provide more detail (min 20 characters).';
    setErrors(next);
    return Object.keys(next).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    setServerError('');
    try {
      // Upload images first
      const imageUrls: string[] = [];
      for (const { file } of images) {
        const fd = new FormData();
        fd.append('file', file);
        const r = await fetch(`${BACKEND}/api/v1/support/upload`, { method: 'POST', body: fd });
        if (!r.ok) throw new Error('Image upload failed.');
        const data = await r.json();
        imageUrls.push(data.url);
      }

      const res = await fetch(`${BACKEND}/api/v1/support`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, imageUrls }),
      });
      if (!res.ok) {
        const data = await res.json();
        throw new Error(data?.message?.[0] ?? data?.message ?? 'Submission failed.');
      }
      setSubmitted(true);
    } catch (err: any) {
      setServerError(err.message ?? 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-ink pt-24 sm:pt-28 pb-24 px-6">
        <div className="max-w-2xl mx-auto">
          <div className="mb-12">
            <p className="font-mono-nums text-xs tracking-widest uppercase text-lavender mb-3">Support</p>
            <h1 className="text-4xl sm:text-5xl font-semibold text-paper tracking-tight mb-3">
              How can we help?
            </h1>
            <p className="text-mist text-base leading-relaxed">
              Report a bug, ask a question, or suggest a feature. Every message goes directly to my inbox and I'll get back to you.
            </p>
          </div>

          {submitted ? (
            <div className="bg-card border border-line/10 rounded-2xl p-10 text-center">
              <div className="w-14 h-14 bg-mint/12 border border-mint/20 rounded-2xl flex items-center justify-center mx-auto mb-5">
                <svg className="w-7 h-7 text-mint" fill="none" viewBox="0 0 24 24">
                  <path d="M5 12l4.5 4.5L19 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </div>
              <h2 className="text-xl font-semibold text-paper mb-2">Message sent</h2>
              <p className="text-mist text-sm leading-relaxed max-w-sm mx-auto">
                Thanks for reaching out. I'll review your message and get back to you at <span className="text-paper font-medium">{form.email}</span>.
              </p>
              <button
                onClick={() => { setSubmitted(false); setForm({ name: '', email: '', subject: '', message: '', type: 'bug' }); setImages([]); }}
                className="mt-6 px-5 py-2.5 border border-line/12 text-paper text-sm font-medium rounded-xl hover:bg-line/8 transition-colors"
              >
                Send another message
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="flex flex-col gap-5">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <FormField label="Name" error={errors.name}>
                  <input type="text" placeholder="Your name" value={form.name} onChange={(e) => set('name', e.target.value)} className={inputCls(!!errors.name)} />
                </FormField>
                <FormField label="Email" error={errors.email}>
                  <input type="email" placeholder="your@email.com" value={form.email} onChange={(e) => set('email', e.target.value)} className={inputCls(!!errors.email)} />
                </FormField>
              </div>

              <FormField label="Type">
                <div className="grid grid-cols-2 gap-2">
                  {TICKET_TYPES.map((t) => (
                    <button key={t.value} type="button" onClick={() => set('type', t.value)}
                      className={`text-left px-4 py-3 rounded-xl border text-sm transition-all duration-150 ${form.type === t.value ? 'border-mint bg-mint/10 text-paper' : 'border-line/10 bg-card text-mist hover:border-line/20 hover:text-paper'}`}>
                      <div className="font-medium text-paper text-xs mb-0.5">{t.label}</div>
                      <div className="text-mist text-xs leading-snug">{t.desc}</div>
                    </button>
                  ))}
                </div>
              </FormField>

              <FormField label="Subject" error={errors.subject}>
                <input type="text" placeholder="Brief summary of your issue" value={form.subject} onChange={(e) => set('subject', e.target.value)} className={inputCls(!!errors.subject)} />
              </FormField>

              <FormField label="Message" error={errors.message}>
                <textarea placeholder="Describe your issue, question, or idea in detail…" rows={6} value={form.message} onChange={(e) => set('message', e.target.value)} className={`${inputCls(!!errors.message)} resize-none`} />
                <span className="text-xs text-mist mt-1 block text-right">{form.message.length} / 2000</span>
              </FormField>

              {/* Image attachments */}
              <FormField label={`Attachments (optional · max ${MAX_IMAGES})`}>
                <input ref={fileRef} type="file" accept="image/*" multiple className="hidden" onChange={(e) => addImages(e.target.files)} />
                {images.length > 0 && (
                  <div className="flex flex-wrap gap-2 mb-2">
                    {images.map((img, i) => (
                      <div key={i} className="relative group w-20 h-20 rounded-lg overflow-hidden border border-line/10">
                        <img src={img.preview} alt="" className="w-full h-full object-cover" />
                        <button type="button" onClick={() => removeImage(i)}
                          className="absolute inset-0 flex items-center justify-center bg-ink/60 opacity-0 group-hover:opacity-100 transition-opacity text-paper text-lg font-bold">
                          ×
                        </button>
                      </div>
                    ))}
                  </div>
                )}
                {images.length < MAX_IMAGES && (
                  <button type="button" onClick={() => fileRef.current?.click()}
                    className="flex items-center gap-2 px-4 py-2.5 border border-dashed border-line/15 rounded-xl text-sm text-mist hover:border-mint hover:text-mint transition-colors">
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
                    </svg>
                    Add screenshot
                  </button>
                )}
                {imageError && <p className="text-coral text-xs mt-1">{imageError}</p>}
              </FormField>

              {serverError && <p className="text-coral text-sm px-1">{serverError}</p>}

              <button type="submit" disabled={loading}
                className="px-6 py-3.5 bg-mint text-ink font-semibold text-sm rounded-xl hover:bg-mint-light disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200">
                {loading ? (images.length > 0 ? 'Uploading…' : 'Sending…') : 'Send Message'}
              </button>
            </form>
          )}

          <div className="mt-14 pt-10 border-t border-line/10">
            <h3 className="text-sm font-semibold text-paper mb-4">Before you write</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {[{ title: 'Read the changelog', desc: 'Your bug might already be fixed.', href: '/changelog' }].map((item) => (
                <a key={item.href} href={item.href}
                  className="flex items-start gap-3 p-4 bg-card border border-line/10 rounded-xl hover:border-line/20 transition-all duration-200 group">
                  <div>
                    <div className="font-medium text-paper text-sm group-hover:text-mint transition-colors">{item.title} →</div>
                    <div className="text-mist text-xs mt-0.5">{item.desc}</div>
                  </div>
                </a>
              ))}
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}

function FormField({ label, error, children }: { label: string; error?: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1.5">
      <label className="text-xs font-semibold text-paper uppercase tracking-wide">{label}</label>
      {children}
      {error && <p className="text-coral text-xs">{error}</p>}
    </div>
  );
}

function inputCls(hasError: boolean) {
  return `w-full px-4 py-3 bg-card border rounded-xl text-sm text-paper placeholder-mist focus:outline-none transition-colors ${hasError ? 'border-coral focus:border-coral' : 'border-line/10 focus:border-mint'}`;
}
