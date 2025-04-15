const colors = require('tailwindcss/colors')

module.exports = {
  content: [
    './app/views/**/*.{html,html.erb,erb}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,rb}',
  ],
  
  // Enable dark mode that works with class instead of media query
  darkMode: 'class',
  
  theme: {
    extend: {
      colors: {
        // Main brand colors
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
      },
      animation: {
        shine: 'shine 1s',
      },
      keyframes: {
        shine: {
          '100%': { left: '125%' },
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}