/** @type {import('tailwindcss').Config} */
export default {
  content: [`./index.html`, `./src/**/*.{js,ts,jsx,tsx}`],
  theme: {
    extend: {
      colors: {
        brand: {
          violet: `#8B5CF6`,
          fuchsia: `#D846EF`,
          50: `#faf5ff`,
          100: `#f3e8ff`,
          200: `#e9d5ff`,
          900: `#581c87`,
        },
      },
      fontFamily: {
        display: [`Bricolage Grotesque`, `system-ui`, `sans-serif`],
        body: [`DM Sans`, `system-ui`, `sans-serif`],
      },
      animation: {
        'fade-in': `fadeIn 0.6s ease-out forwards`,
        'slide-up': `slideUp 0.6s ease-out forwards`,
        float: `float 6s ease-in-out infinite`,
        'pulse-slow': `pulse 4s ease-in-out infinite`,
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: `0` },
          '100%': { opacity: `1` },
        },
        slideUp: {
          '0%': { opacity: `0`, transform: `translateY(20px)` },
          '100%': { opacity: `1`, transform: `translateY(0)` },
        },
        float: {
          '0%, 100%': { transform: `translateY(0) rotate(0deg)` },
          '50%': { transform: `translateY(-20px) rotate(3deg)` },
        },
      },
    },
  },
  plugins: [],
};
