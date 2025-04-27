/**
 * Prebuild script to extract localization data
 * This runs automatically before building the Astro site
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { dirname } from "path";
import { globSync } from "glob";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Define paths
const projectRoot = path.resolve(__dirname, "..");
const outputDir = path.join(__dirname, "public", "i18n");
const globsPattern = path.join(projectRoot, "Blankie", "*.xcstrings");

// Ensure output directory exists
console.log(`\n✨ Prebuild: Ensuring i18n directory exists...`);
fs.mkdirSync(outputDir, { recursive: true });

// Extraction logic integrated directly
console.log(`✨ Prebuild: Extracting localization data...`);
try {
  // Find all matching files
  console.log(`Looking for files matching: ${globsPattern}`);
  const files = globSync(globsPattern);

  if (files.length === 0) {
    console.error(`❌ Prebuild: No files found matching: ${globsPattern}`);
    process.exit(1);
  }

  console.log(`Found ${files.length} file(s)`);

  // Initialize result object
  const result = {
    metadata: {
      extractedAt: new Date().toISOString(),
      tool: "blanki8n-prebuild",
      files: files,
    },
    strings: {},
  };

  // Process each file
  files.forEach((file) => {
    console.log(`Processing ${file}`);
    try {
      const content = fs.readFileSync(file, "utf8");
      const json = JSON.parse(content);

      // Extract strings and their metadata
      if (json.strings) {
        Object.keys(json.strings).forEach((key) => {
          const item = json.strings[key];

          if (item.shouldTranslate === false) {
            return; // Skip strings that shouldn't be translated
          }

          // Initialize key in result if it doesn't exist
          if (!result.strings[key]) {
            result.strings[key] = {};
          }

          // Extract comment if available
          if (item.comment) {
            result.strings[key].comment = item.comment;
          }

          // Extract English strings if available (source language)
          if (item.localizations?.en?.stringUnit?.value) {
            result.strings[key].en = {
              value: item.localizations.en.stringUnit.value,
              state: item.localizations.en.stringUnit.state || "translated",
            };
          }

          // Extract other locales if available
          if (item.localizations) {
            Object.keys(item.localizations).forEach((locale) => {
              if (
                locale !== "en" &&
                item.localizations[locale]?.stringUnit?.value
              ) {
                result.strings[key][locale] = {
                  value: item.localizations[locale].stringUnit.value,
                  state:
                    item.localizations[locale].stringUnit.state || "translated",
                };
              }
            });
          }
        });
      }
    } catch (error) {
      console.error(`Error processing ${file}: ${error.message}`);
    }
  });

  // Save the complete extraction result
  fs.writeFileSync(
    path.join(outputDir, "extracted.json"),
    JSON.stringify(result, null, 2)
  );
  console.log(
    `Extraction complete. Full data saved to ${path.join(
      outputDir,
      "extracted.json"
    )}`
  );

  // Find all languages in the data
  const languages = new Set(["en"]);
  Object.keys(result.strings).forEach((key) => {
    Object.keys(result.strings[key]).forEach((lang) => {
      if (lang !== "comment" && lang !== "context") {
        languages.add(lang);
      }
    });
  });

  console.log(
    `Found ${languages.size} languages: ${Array.from(languages).join(", ")}`
  );

  // Create per-language files
  languages.forEach((lang) => {
    if (lang === "en") return; // Skip English as it's the source language

    const langData = {
      metadata: {
        language: lang,
        extractedAt: result.metadata.extractedAt,
        sourceFiles: result.metadata.files,
      },
      statistics: {},
      strings: {},
    };

    let totalStrings = 0;
    let translatedStrings = 0;
    let needsReviewStrings = 0;

    // Format each string for this language
    Object.keys(result.strings).forEach((key) => {
      // Only count strings that have an English source
      if (result.strings[key].en) {
        totalStrings++;

        if (result.strings[key][lang]) {
          langData.strings[key] = {
            source: result.strings[key].en.value,
            target: result.strings[key][lang].value,
            state: result.strings[key][lang].state || "translated",
            comment: result.strings[key].comment || "",
          };

          if (result.strings[key][lang].state === "needs_review") {
            needsReviewStrings++;
          } else if (result.strings[key][lang].state === "translated") {
            translatedStrings++;
          }
        } else {
          // Include untranslated strings with empty target
          langData.strings[key] = {
            source: result.strings[key].en.value,
            target: "",
            state: "needs_translation",
            comment: result.strings[key].comment || "",
          };
        }
      }
    });

    langData.statistics = {
      totalStrings,
      translatedStrings,
      needsReviewStrings,
      translationPercentage: totalStrings
        ? Math.round((translatedStrings / totalStrings) * 100)
        : 0,
      needsReviewPercentage: totalStrings
        ? Math.round((needsReviewStrings / totalStrings) * 100)
        : 0,
    };

    // Save language-specific file
    const langFileName = `${lang}.json`;
    fs.writeFileSync(
      path.join(outputDir, langFileName),
      JSON.stringify(langData, null, 2)
    );
    console.log(
      `Created language file: ${langFileName} (${langData.statistics.translationPercentage}% translated, ${langData.statistics.needsReviewPercentage}% needs review)`
    );
  });

  // Create a language index file with translation statistics
  const langIndex = {
    metadata: {
      extractedAt: result.metadata.extractedAt,
      languages: Array.from(languages),
    },
    statistics: {},
  };

  // Calculate statistics for each language
  languages.forEach((lang) => {
    if (lang === "en") return; // Skip English as it's the source language

    let totalStrings = 0;
    let translatedStrings = 0;
    let needsReviewStrings = 0;

    Object.keys(result.strings).forEach((key) => {
      if (result.strings[key].en) {
        totalStrings++;

        if (result.strings[key][lang]) {
          if (result.strings[key][lang].state === "needs_review") {
            needsReviewStrings++;
          } else if (result.strings[key][lang].state === "translated") {
            translatedStrings++;
          }
        }
      }
    });

    langIndex.statistics[lang] = {
      totalStrings,
      translatedStrings,
      needsReviewStrings,
      translationPercentage: totalStrings
        ? Math.round((translatedStrings / totalStrings) * 100)
        : 0,
      needsReviewPercentage: totalStrings
        ? Math.round((needsReviewStrings / totalStrings) * 100)
        : 0,
    };
  });

  fs.writeFileSync(
    path.join(outputDir, "languages.json"),
    JSON.stringify(langIndex, null, 2)
  );

  // Write a summary.txt with dynamic commit info
  const summaryLines = Object.keys(langIndex.statistics)
    .sort()
    .map((lang) => {
      const stats = langIndex.statistics[lang];
      return `${lang} ${stats.translationPercentage}%`;
    });

  const commitSummary = `Update i18n: ${summaryLines.join(", ")} — ${new Date()
    .toISOString()
    .slice(0, 10)}`;
  fs.writeFileSync(path.join(outputDir, "summary.txt"), commitSummary);

  // Print translation summary
  console.log("\n✨ Prebuild: Translation Progress Summary:");
  console.log("============================");
  Object.keys(langIndex.statistics)
    .sort()
    .forEach((lang) => {
      const stats = langIndex.statistics[lang];
      console.log(
        `${lang}: ${stats.translationPercentage}% translated, ${stats.needsReviewPercentage}% needs review (${stats.translatedStrings}/${stats.totalStrings} translated, ${stats.needsReviewStrings}/${stats.totalStrings} needs review)`
      );
    });
  console.log("============================");

  // Count the generated files
  const generatedFiles = fs.readdirSync(outputDir);
  console.log(
    `✨ Prebuild: Generated ${generatedFiles.length} localization files\n`
  );
} catch (error) {
  console.error(
    `❌ Prebuild: Localization extraction failed: ${error.message}`
  );
  process.exit(1);
}
