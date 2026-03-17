const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Pretendard Variable', 'Pretendard', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        primary: {
          50:  '#f0fffe',
          100: '#ccfbf7',
          200: '#99f6ef',
          300: '#5eead4',
          400: '#2dd4bf',
          500: '#14d4c0',
          600: '#0eb8a4',
          700: '#0d9488',
          800: '#0f766e',
          900: '#115e59',
          950: '#042f2e',
        },
        carrot: {
          50: '#fff7ed',
          100: '#ffedd5',
          200: '#fed7aa',
          300: '#fdba74',
          400: '#fb923c',
          500: '#f97316',
          600: '#ea580c',
        },
      },
      borderRadius: {
        '2xl': '1rem',
        '3xl': '1.5rem',
      },
      spacing: {
        'safe': 'env(safe-area-inset-bottom)',
      },
    },
  },
  plugins: [],
}
