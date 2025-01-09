/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        "primary-blue": "#0071e3",
        "deep-blue": "#004cc2",
        "dark-gray": "#1a1a1a",
        "light-gray": "#f0f0f0",
        "coming-soon": "#71717a",
        "open-source-green": "#22c55e",
      },
      backgroundImage: {
        "bg-gradient-light":
          "linear-gradient(180deg, #f0f0f0 0%, #ffffff 100%)",
        "bg-gradient-dark": "linear-gradient(180deg, #1a1a1a 0%, #0a0a0a 100%)",
      },
      textColor: {
        skin: {
          base: "var(--color-text-base)",
          muted: "var(--color-text-muted)",
          inverted: "var(--color-text-inverted)",
        },
      },
      backgroundColor: {
        skin: {
          fill: "var(--color-bg-fill)",
          card: "var(--color-bg-card)",
        },
      },
    },
  },
  plugins: [],
};
