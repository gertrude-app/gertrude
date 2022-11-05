module.exports = {
  content: [
    `./src/**/*.tsx`,
    `../dash/components/src/**/*.tsx`,
    `../marketing/components/src/**/*.tsx`,
    `../shared/components/src/**/*.tsx`,
  ],
  presets: [require(`@shared/tailwind`)],
};
