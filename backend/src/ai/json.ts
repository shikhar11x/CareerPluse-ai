/** Parses model output that should be JSON but may be wrapped in code fences or prose. */
export function parseJsonLoose(raw: string): unknown {
  const text = raw
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/, '');
  try {
    return JSON.parse(text);
  } catch {
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start === -1 || end <= start) throw new Error('No JSON object found');
    return JSON.parse(text.slice(start, end + 1));
  }
}