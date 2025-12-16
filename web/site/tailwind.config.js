const defaultTheme = require(`tailwindcss/defaultTheme`);

module.exports = {
  presets: [require(`@shared/tailwind`)],
  plugins: [require(`@tailwindcss/typography`)],
  darkMode: `class`,
  content: [
    `./docs/**/*.tsx`,
    `./pages/**/*.tsx`,
    `./markdoc/**/*.md`,
    `./app/**/*.tsx`,
    `./components/**/*.tsx`,
    `../components/**/*.tsx`,
    `../shared/components/**/*.tsx`,
  ],
  theme: {
    extend: {
      fontFamily: {
        'docs-inter': [`Inter-Docs`, ...defaultTheme.fontFamily.sans],
        lexend: [`Lexend`, ...defaultTheme.fontFamily.sans],
      },
      maxWidth: {
        '8xl': `88rem`,
      },
      colors: {
        purple: {
          975: `#281445`,
        },
      },
      keyframes: {
        blink: {
          '0%, 100%': { opacity: `1` },
          '50%': { opacity: `0` },
        },
        fadeIn: {
          '0%': { opacity: `0`, transform: `translateY(100px)` },
          '100%': { opacity: `1`, transform: `translateY(0)` },
        },
      },
      animation: {
        blink: `blink 1s step-end infinite`,
        fadeIn: `fadeIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)`,
      },
    },
  },
};
