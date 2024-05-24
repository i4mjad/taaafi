/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,ts}"],
  theme: {
    screens: {
      xs: {
        min: "0px",
        max: "599.99px",
      },
      md: {
        min: "960px",
        max: "1279.99px",
      },
      lg: {
        min: "1280px",
        max: "599.99px",
      },
      sm: {
        min: "600px",
        max: "959.99px",
      },

      "lt-xl": {
        max: "1919.99px",
      },
      "lt-lg": {
        max: "1279.99px",
      },
      "lt-md": {
        max: "959.99px",
      },

      "lt-sm": {
        max: "599.99px",
      },
      "gt-md": {
        min: "1280px",
      },
      "gt-sm": {
        min: "960px",
      },
      "gt-xs": {
        min: "600px",
      },
    },
    extend: {},
  },
  plugins: [],
};

