// utils/csv.ts
export function convertTranslationToCSV(strings: Record<string, any>): string {
  // CSV headers
  let csv = "key,source,target,state,comment\n";

  // Add each string as a row
  Object.entries(strings).forEach(([key, item]) => {
    // Escape quotes in fields for CSV compatibility
    const escapedKey = escapeCSVField(key);
    const escapedSource = escapeCSVField(item.source);
    const escapedTarget = escapeCSVField(item.target || "");
    const escapedState = escapeCSVField(item.state);
    const escapedComment = escapeCSVField(item.comment || "");

    // Add row
    csv += `${escapedKey},${escapedSource},${escapedTarget},${escapedState},${escapedComment}\n`;
  });

  return csv;
}

// Helper function to escape CSV fields properly
function escapeCSVField(field: string): string {
  if (!field) return '""';

  // If the field contains commas, newlines, or quotes, wrap it in quotes and escape internal quotes
  const needsQuotes = /[,\r\n"]/g.test(field);

  if (needsQuotes) {
    // Replace double quotes with two double quotes (CSV escaping)
    const escaped = field.replace(/"/g, '""');
    return `"${escaped}"`;
  }

  return `"${field}"`; // Always wrap in quotes for consistency
}
