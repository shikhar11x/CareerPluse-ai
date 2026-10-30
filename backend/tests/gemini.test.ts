import { describe, expect, it, vi } from 'vitest';

import { GeminiProvider } from '../src/ai/gemini';

const reply = (body: unknown, status = 200) =>
  Promise.resolve(new Response(JSON.stringify(body), { status }));

const make = (impl: (...a: unknown[]) => Promise<Response>) =>
  new GeminiProvider('KEY', 'model-x', vi.fn(impl) as unknown as typeof fetch);

describe('GeminiProvider', () => {
  it('sends the key as a header (not in the URL) and the request in Gemini format', async () => {
    const fetchMock = vi.fn(() => reply({ candidates: [{ content: { parts: [{ text: 'Hello' }] } }] }));
    const p = new GeminiProvider('KEY', 'model-x', fetchMock as unknown as typeof fetch);

    const out = await p.generate({
      system: 'SYS',
      turns: [{ role: 'user', text: 'hi' }],
      json: true,
      temperature: 0.2,
      maxOutputTokens: 50,
    });

    expect(out).toBe('Hello');
    const [url, init] = fetchMock.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toContain('/models/model-x:generateContent');
    expect(url).not.toContain('KEY');
    expect((init.headers as Record<string, string>)['x-goog-api-key']).toBe('KEY');
    const body = JSON.parse(init.body as string);
    expect(body.systemInstruction.parts[0].text).toBe('SYS');
    expect(body.contents).toEqual([{ role: 'user', parts: [{ text: 'hi' }] }]);
    expect(body.generationConfig).toMatchObject({
      temperature: 0.2,
      maxOutputTokens: 50,
      responseMimeType: 'application/json',
    });
  });

  it('ignores "thought" parts and joins the rest', async () => {
    const p = make(() =>
      reply({
        candidates: [
          { content: { parts: [{ text: 'secret thinking', thought: true }, { text: 'A' }, { text: 'B' }] } },
        ],
      }),
    );
    expect(await p.generate({ system: 's', turns: [] })).toBe('AB');
  });

  it('maps 429 to a quota error', async () => {
    const p = make(() => reply({}, 429));
    await expect(p.generate({ system: 's', turns: [] })).rejects.toMatchObject({
      status: 429,
      code: 'ai_quota',
    });
  });

  it('maps bad key/model to ai_not_configured', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    for (const status of [400, 401, 403, 404]) {
      const p = make(() => reply({ error: 'x' }, status));
      await expect(p.generate({ system: 's', turns: [] })).rejects.toMatchObject({
        status: 503,
        code: 'ai_not_configured',
      });
    }
  });

  it('maps server errors, network failures and empty output to 502', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    await expect(make(() => reply({}, 500)).generate({ system: 's', turns: [] })).rejects.toMatchObject({
      status: 502,
    });
    await expect(
      make(() => Promise.reject(new Error('offline'))).generate({ system: 's', turns: [] }),
    ).rejects.toMatchObject({ status: 502, code: 'ai_unavailable' });
    await expect(make(() => reply({ candidates: [] })).generate({ system: 's', turns: [] })).rejects.toMatchObject({
      status: 502,
      code: 'ai_empty',
    });
  });
});