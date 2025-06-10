module.exports = {
  presets: [require(`@shared/tailwind`)],
  content: [
    `./src/components/**/*.tsx`,
    `../components/src/**/*.tsx`,
    `../../shared/components/**/*.tsx`,
  ],
};
