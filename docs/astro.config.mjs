// @ts-check
import { defineConfig } from "astro/config";
import tailwind from "@astrojs/tailwind";
import playformCompress from "@playform/compress";

// https://astro.build/config
export default defineConfig({
  integrations: [tailwind(), playformCompress()],
  site: "https://blankie.rest",
  output: "static",
});
