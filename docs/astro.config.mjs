// @ts-check
import { defineConfig } from "astro/config";
import tailwind from "@astrojs/tailwind";

import playformCompress from "@playform/compress";

// https://astro.build/config
export default defineConfig({
  integrations: [tailwind(), playformCompress()],
  site: "https://blankie.rest",
  server: {
    headers: {
      // Set cache-control headers for all static assets
      "/*.{js,css,jpg,jpeg,png,gif,ico,svg,webp,mp4}":
        "Cache-Control: public, max-age=31536000, immutable", // 1 year cache
      // Specific headers for HTML files
      "/*.html": "Cache-Control: public, max-age=3600", // 1 hour cache
    },
  },
});
