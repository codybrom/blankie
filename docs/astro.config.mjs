// @ts-check
import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";
import playformCompress from "@playform/compress";

// https://astro.build/config
export default defineConfig({
  integrations: [playformCompress()],
  site: "https://blankie.rest",
  output: "static",
  vite: {
    plugins: [tailwindcss()],
  },
});
