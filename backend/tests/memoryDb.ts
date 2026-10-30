/* eslint-disable @typescript-eslint/no-explicit-any */
import type { SupabaseClient } from '@supabase/supabase-js';

type Row = Record<string, any>;
type Tables = Record<string, Row[]>;
type Result = { data: any; error: { code?: string; message: string } | null; count?: number };

const UNIQUE: Record<string, string[]> = {
  interview_messages: ['interview_id', 'seq'],
  interview_feedback: ['interview_id'],
};

/** Tiny in-memory stand-in for the parts of the Supabase query builder we use. */
class Query implements PromiseLike<Result> {
  private op: 'select' | 'insert' | 'update' | 'delete' = 'select';
  private payload: any;
  private filters: [string, unknown][] = [];
  private orderBy?: string;
  private asc = true;
  private max?: number;
  private returning = false;
  private head = false;
  private wantCount = false;

  constructor(
    private readonly tables: Tables,
    private readonly table: string,
    private readonly nextId: () => string,
  ) {}

  select(_cols?: string, opts?: { count?: string; head?: boolean }) {
    if (this.op !== 'select') this.returning = true;
    this.head = !!opts?.head;
    this.wantCount = !!opts?.count;
    return this;
  }
  insert(p: any) {
    this.op = 'insert';
    this.payload = p;
    return this;
  }
  update(p: any) {
    this.op = 'update';
    this.payload = p;
    return this;
  }
  delete() {
    this.op = 'delete';
    return this;
  }
  eq(c: string, v: unknown) {
    this.filters.push([c, v]);
    return this;
  }
  order(c: string, o?: { ascending?: boolean }) {
    this.orderBy = c;
    this.asc = o?.ascending !== false;
    return this;
  }
  limit(n: number) {
    this.max = n;
    return this;
  }
  maybeSingle() {
    return this.run('maybe');
  }
  single() {
    return this.run('single');
  }
  then<A, B>(ok?: (v: Result) => A | PromiseLike<A>, bad?: (e: unknown) => B | PromiseLike<B>) {
    return this.run('many').then(ok, bad);
  }

  private matches(r: Row) {
    return this.filters.every(([c, v]) => r[c] === v);
  }

  private async run(shape: 'many' | 'maybe' | 'single'): Promise<Result> {
    const rows = (this.tables[this.table] ??= []);
    let out: Row[] = [];

    if (this.op === 'insert') {
      const incoming: Row[] = Array.isArray(this.payload) ? this.payload : [this.payload];
      const keys = UNIQUE[this.table];
      for (const r of incoming) {
        if (keys && rows.some((e) => keys.every((k) => e[k] === r[k]))) {
          return { data: null, error: { code: '23505', message: 'duplicate key' } };
        }
      }
      for (const r of incoming) {
        const row: Row = { id: this.nextId(), created_at: new Date().toISOString(), ...r };
        if (this.table === 'interviews') {
          row.status ??= 'in_progress';
          row.started_at ??= new Date().toISOString();
          row.completed_at ??= null;
        }
        if (this.table === 'interview_feedback') row.is_ai_estimate ??= true;
        rows.push(row);
        out.push(row);
      }
      if (!this.returning) return { data: null, error: null };
    } else if (this.op === 'update') {
      out = rows.filter((r) => this.matches(r));
      out.forEach((r) => Object.assign(r, this.payload));
      if (!this.returning) return { data: null, error: null };
    } else if (this.op === 'delete') {
      out = rows.filter((r) => this.matches(r));
      this.tables[this.table] = rows.filter((r) => !this.matches(r));
      if (this.table === 'interviews') {
        const gone = new Set(out.map((r) => r.id));
        for (const t of ['interview_messages', 'interview_feedback']) {
          this.tables[t] = (this.tables[t] ?? []).filter((r) => !gone.has(r.interview_id));
        }
      }
      if (!this.returning) return { data: null, error: null };
    } else {
      out = rows.filter((r) => this.matches(r));
    }

    if (this.orderBy) {
      const k = this.orderBy;
      out = [...out].sort((a, b) => (a[k] < b[k] ? -1 : a[k] > b[k] ? 1 : 0) * (this.asc ? 1 : -1));
    }
    if (this.max !== undefined) out = out.slice(0, this.max);

    const count = this.wantCount ? out.length : undefined;
    if (this.head) return { data: null, error: null, count };
    if (shape === 'maybe') return { data: out[0] ?? null, error: null, count };
    if (shape === 'single') {
      return out.length === 1
        ? { data: out[0], error: null, count }
        : { data: null, error: { message: 'expected one row' }, count };
    }
    return { data: out, error: null, count };
  }
}

export function memoryDb(seed: Tables = {}) {
  const tables: Tables = {
    interviews: [],
    interview_messages: [],
    interview_feedback: [],
    ...seed,
  };
  let n = 0;
  const db = { from: (t: string) => new Query(tables, t, () => `id-${++n}`) };
  return { db: db as unknown as SupabaseClient, tables };
}

export const interviewRow = (over: Row = {}): Row => ({
  id: 'i1',
  user_id: 'u1',
  target_role: 'Flutter Developer',
  interview_type: 'technical',
  difficulty: 'beginner',
  duration_minutes: 5, // -> 3 questions
  mode: 'text',
  status: 'in_progress',
  started_at: '2026-01-01T00:00:00Z',
  completed_at: null,
  created_at: '2026-01-01T00:00:00Z',
  ...over,
});

export const messageRow = (seq: number, role: 'interviewer' | 'candidate', content: string): Row => ({
  id: `m${seq}`,
  interview_id: 'i1',
  user_id: 'u1',
  seq,
  role,
  content,
  created_at: '2026-01-01T00:00:00Z',
});