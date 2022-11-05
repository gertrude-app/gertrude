const defaultTheme = require(`tailwindcss/defaultTheme`);

module.exports = {
  plugins: [require(`@tailwindcss/forms`)],
  theme: {
    screens: {
      xs: `500px`,
      sm: `640px`,
      md: `768px`,
      lg: `1024px`,
      'lg+': `1152px`,
      xl: `1280px`,
      '2xl': `1600px`,
    },
    extend: {
      spacing: {
        112: `28rem`,
        128: `32rem`,
        152: `38rem`,
        176: `44rem`,
      },
      fontFamily: {
        inter: [`Inter`, ...defaultTheme.fontFamily.sans],
        lato: [`lato`, ...defaultTheme.fontFamily.sans],
      },
    },
  },
};
