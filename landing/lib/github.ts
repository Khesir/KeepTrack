const GITHUB_REPO = 'Khesir/KeepTrack';

export type ChangelogRelease = {
  tag: string;
  date: string;
  isLatest: boolean;
  notes: string[];
  footnote?: string;
  compareUrl?: string;
  compareLabel?: string;
};

export type LatestRelease = {
  tag: string;
  version: string;
  date: string;
  windowsUrl?: string;
  androidUrl?: string;
};

type GithubAsset = {
  name: string;
  browser_download_url: string;
};

type GithubReleaseApi = {
  tag_name: string;
  published_at: string | null;
  body: string | null;
  draft: boolean;
  assets: GithubAsset[];
};

export async function getChangelog(): Promise<ChangelogRelease[]> {
  try {
    const res = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=15`, {
      headers: { Accept: 'application/vnd.github+json' },
      next: { revalidate: 3600 },
    });
    if (!res.ok) return [];

    const data: GithubReleaseApi[] = await res.json();

    return data
      .filter((r) => !r.draft)
      .map((r, i) => {
        const { notes, compareUrl, compareLabel } = parseReleaseBody(r.body ?? '');
        return {
          tag: r.tag_name,
          date: formatDate(r.published_at),
          isLatest: i === 0,
          notes,
          compareUrl,
          compareLabel,
        };
      });
  } catch {
    return [];
  }
}

export async function getLatestRelease(): Promise<LatestRelease | null> {
  try {
    const res = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/releases/latest`, {
      headers: { Accept: 'application/vnd.github+json' },
      next: { revalidate: 3600 },
    });
    if (!res.ok) return null;

    const r: GithubReleaseApi = await res.json();
    const windowsUrl = r.assets.find((a) => /\.exe$/i.test(a.name))?.browser_download_url;
    const androidUrl = r.assets.find((a) => /\.apk$/i.test(a.name))?.browser_download_url;

    return {
      tag: r.tag_name,
      version: r.tag_name.replace(/^v/, ''),
      date: formatDate(r.published_at),
      windowsUrl,
      androidUrl,
    };
  } catch {
    return null;
  }
}

function formatDate(iso: string | null): string {
  if (!iso) return '';
  return new Date(iso).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

function parseReleaseBody(body: string): {
  notes: string[];
  compareUrl?: string;
  compareLabel?: string;
} {
  const notes: string[] = [];
  let compareUrl: string | undefined;
  let compareLabel: string | undefined;

  for (const rawLine of body.split('\n')) {
    const line = rawLine.trim();
    if (!line) continue;

    const compareMatch = line.match(/\*\*Full Changelog\*\*:\s*(https?:\/\/\S+)/i);
    if (compareMatch) {
      compareUrl = compareMatch[1];
      compareLabel = compareUrl.replace(/^https?:\/\//, '');
      continue;
    }

    const bullet = line.match(/^[-*]\s+(.*)$/);
    if (bullet) notes.push(cleanNote(bullet[1]));
  }

  return { notes, compareUrl, compareLabel };
}

function cleanNote(text: string): string {
  return text
    .replace(/\s+by @[\w-]+ in (#\d+|https?:\/\/\S+)$/i, '')
    .replace(/\*\*(.*?)\*\*/g, '$1')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .trim();
}
