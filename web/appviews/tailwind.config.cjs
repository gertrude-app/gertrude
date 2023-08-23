module.exports = {
  presets: [require(`@shared/tailwind`)],
  content: [
    `./src/**/*.tsx`,
    `../shared/components/src/Logo.tsx`,
    `../shared/components/src/Button.tsx`,
    `../shared/components/src/TextInput.tsx`,
    `../shared/components/src/Toggle.tsx`,
    `../shared/components/src/Loading.tsx`,
    `../shared/components/src/SelectMenu.tsx`,
    `../shared/components/src/PillBadge.tsx`,
  ],
  darkMode: `class`,
};
