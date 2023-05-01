const defaultTheme = require(`tailwindcss/defaultTheme`);

module.exports = {
  plugins: [require(`@tailwindcss/forms`)],
  darkMode: `class`,
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
      animation: {
        'bounce-right': `bounce-right 0.5s linear infinite`,
      },
      keyframes: {
        'bounce-right': {
          '0%, 100%': {
            transform: `translateX(0)`,
            animationTimingFunction: `cubic-bezier(0.8, 0, 1, 1)`,
          },
          '50%': {
            transform: `translateX(10px)`,
            animationTimingFunction: `cubic-bezier(0, 0, 0.2, 1)`,
          },
        },
        'loader-bounce': {
          '0%': {
            height: `18px`,
            opacity: `1`,
            width: `18px`,
            marginLeft: `0`,
            marginRight: `0`,
            marginTop: `0px`,
          },
          '15%': {
            height: `18px`,
            opacity: `1`,
            width: `18px`,
            marginLeft: `0`,
            marginRight: `0`,
            marginTop: `0px`,
          },
          '30%': {
            height: `60px`,
            opacity: `0.8`,
            width: `10px`,
            marginLeft: `4px`,
            marginRight: `4px`,
            marginTop: `-4px`,
          },
          '50%': {
            height: `18px`,
            opacity: `1`,
            width: `18px`,
            marginLeft: `0`,
            marginRight: `0`,
            marginTop: `38px`,
          },
          '65%': {
            height: `18px`,
            opacity: `1`,
            width: `18px`,
            marginLeft: `0`,
            marginRight: `0`,
            marginTop: `38px`,
          },
          '80%': {
            height: `60px`,
            opacity: `0.8`,
            width: `10px`,
            marginLeft: `4px`,
            marginRight: `4px`,
            marginTop: `0px`,
          },
          '100%': {
            height: `18px`,
            opacity: `1`,
            width: `18px`,
            marginLeft: `0`,
            marginRight: `0`,
            marginTop: `0px`,
          },
        },
      },
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
