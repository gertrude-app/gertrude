module.exports = {
  presets: [require(`@shared/tailwind`)],
  content: [
    `./src/**/*.tsx`,
    `../shared/components/src/Button.tsx`,
    `../shared/components/src/Loading.tsx`,
  ],
  darkMode: `class`,
};
