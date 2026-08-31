/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    unoptimized: true,
  },
  async redirects() {
    return [
      {
        source: '/announcements',
        destination: '/changelog',
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
