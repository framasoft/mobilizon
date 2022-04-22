function withOpacityValue(variable) {
  return ({ opacityValue }) => {
    if (opacityValue === undefined) {
      return `rgb(var(${variable}))`;
    }
    return `rgb(var(${variable}) / ${opacityValue})`;
  };
}

module.exports = {
  content: ["./public/**/*.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: withOpacityValue("--color-primary"),
        secondary: withOpacityValue("--color-secondary"),
        "violet-title": withOpacityValue("--color-violet-title"),
      },
      lineClamp: {
        10: "10",
      },
    },
  },
  plugins: [require("@tailwindcss/line-clamp")],
};
