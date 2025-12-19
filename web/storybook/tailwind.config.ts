import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    `./stories/**/*.tsx`,
    `../dash/components/src/**/*.tsx`,
    `../site/**/*.tsx`,
    `../shared/components/src/**/*.tsx`,
    `../appviews/src/**/*.tsx`,
  ],
  presets: [require(`@shared/tailwind`)],
};
export default config;
