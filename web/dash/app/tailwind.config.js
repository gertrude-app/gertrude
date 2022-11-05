module.exports = {
  presets: [require(`@shared/tailwind`)],
  content: [
    `./src/components/**/*.tsx`,
    `../components/**/*.tsx`,
    `../../shared/components/**/*.tsx`,
  ],
};
