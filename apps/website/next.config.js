/** @type {import('next').NextConfig} */
const nextConfig = {
  // Remove the i18n config as it's not used in the new app router
  images: {
    domains: [
      'images.unsplash.com',
      'unsplash.com'
    ],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
        port: '',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'unsplash.com',
        port: '',
        pathname: '/**',
      }
    ]
  }
}

module.exports = nextConfig 