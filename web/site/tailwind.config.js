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
    },
  },
};
