import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        background: '#f7f9fc',
        surface: '#ffffff',
        'surface-container': '#eceef1',
        'surface-container-low': '#f2f4f7',
        'border-subtle': '#E0E5EB',
        primary: '#00355f',
        'primary-container': '#0f4c81',
        secondary: '#0060a8',
        success: '#2E7D32',
        warning: '#ED6C02',
        error: '#D32F2F',
        'on-surface': '#191c1e',
        'on-surface-variant': '#455A64'
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif']
      },
      borderRadius: {
        DEFAULT: '8px',
        lg: '12px',
        xl: '16px'
      },
      boxShadow: {
        card: '0 2px 8px rgba(15, 76, 129, 0.08)'
      }
    }
  },
  plugins: []
};

export default config;

