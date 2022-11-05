module.exports = {
  presets: [require(`@shared/tailwind`)],
  content: [
    `./pages/**/*.tsx`,
    `../components/**/*.tsx`,
    `../../shared/components/**/*.tsx`,
  ],
};
