import { HttpError } from '../middleware/errors';
import type { AiProvider, GenerateRequest } from './types';

interface GeminiResponse {
  candidates?: { content?: { parts?: { text?: string; thought?: boolean }[] } }[];
}

/** Google Gemini via the plain REST API (no SDK, nothing to keep in sync). */
export class GeminiProvider implements AiProvider {
  constructor(
    private readonly apiKey: string,
    private readonly model: string,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async generate(req: GenerateRequest): Promise<string> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(this.model)}:generateContent`;
    const body = {
      systemInstruction: { parts: [{ text: req.system }] },
      contents: req.turns.map((t) => ({ role: t.role, parts: [{ text: t.text }] })),
      generationConfig: {
        temperature: req.temperature ?? 0.7,
        maxOutputTokens: req.maxOutputTokens ?? 1024,
        ...(req.json ? { responseMimeType: 'application/json' } : {}),
      },
    };

    let res: Response;
    try {
      res = await this.fetchImpl(url, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': this.apiKey },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(30_000),
      });
    } catch {
      throw new HttpError(502, 'ai_unavailable', 'The AI service could not be reached. Try again.');
    }

    if (res.status === 429) {
      throw new HttpError(
        429,
        'ai_quota',
        'AI usage limit reached. Wait a minute and try again.',
      );
    }
    if (!res.ok) {
      console.error('[gemini]', res.status, (await res.text().catch(() => '')).slice(0, 300));
      if (res.status === 400 || res.status === 401 || res.status === 403 || res.status === 404) {
        throw new HttpError(
          503,
          'ai_not_configured',
          'The AI key or model is not valid. Check AI_API_KEY and GEMINI_MODEL on the server.',
        );
      }
      throw new HttpError(502, 'ai_unavailable', 'The AI service had a problem. Try again.');
    }

    const json = (await res.json().catch(() => ({}))) as GeminiResponse;
    const parts = json.candidates?.[0]?.content?.parts ?? [];
    const text = parts
      .filter((p) => !p.thought && typeof p.text === 'string')
      .map((p) => p.text)
      .join('')
      .trim();
    if (!text) {
      throw new HttpError(502, 'ai_empty', 'The AI returned an empty response. Try again.');
    }
    return text;
  }
}