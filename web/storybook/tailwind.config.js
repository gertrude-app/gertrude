module.exports = {
  content: [
    `./src/**/*.tsx`,
    `../dash/components/src/**/*.tsx`,
    `../site/components/src/**/*.tsx`,
    `../shared/components/src/**/*.tsx`,
    `../appviews/src/**/*.tsx`,
  ],
  presets: [require(`@shared/tailwind`)],
};
