module.exports = {
  presets: [require(`@shared/tailwind`)],
  content: [`./src/**/*.tsx`, `../shared/components/src/**/*.tsx`],
  darkMode: `class`,
};
