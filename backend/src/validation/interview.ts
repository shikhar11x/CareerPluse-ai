import { z } from 'zod';

export const createInterviewSchema = z.object({
  targetRole: z.string().trim().min(1).max(100),
  interviewType: z.enum(['technical', 'hr', 'behavioral', 'mixed']),
  difficulty: z.enum(['beginner', 'intermediate', 'advanced']),
  durationMinutes: z.number().int().min(5).max(60),
  mode: z.enum(['text', 'voice']),
});
export type CreateInterviewInput = z.infer<typeof createInterviewSchema>;

export const answerSchema = z.object({
  answer: z.string().trim().min(1).max(2000),
});

export const idParam = z.string().uuid();

const score = z.number().transform((n) => Math.min(100, Math.max(0, Math.round(n))));
const strings = (max: number) =>
  z
    .array(z.string())
    .default([])
    .transform((a) =>
      a
        .map((s) => s.trim().slice(0, 500))
        .filter(Boolean)
        .slice(0, max),
    );

/** Shape we require from the AI. Out-of-range scores are clamped, not trusted. */
export const feedbackSchema = z.object({
  communicationScore: score,
  technicalScore: score,
  relevanceScore: score,
  strengths: strings(5),
  weaknesses: strings(5),
  missedConcepts: strings(6),
  improvedAnswers: z
    .array(z.object({ question: z.string(), suggestion: z.string() }))
    .default([])
    .transform((a) =>
      a
        .map((x) => ({
          question: x.question.trim().slice(0, 500),
          suggestion: x.suggestion.trim().slice(0, 1500),
        }))
        .filter((x) => x.question && x.suggestion)
        .slice(0, 4),
    ),
  nextSteps: strings(5),
});
export type AiFeedback = z.infer<typeof feedbackSchema>;

/**
 * Overall score is computed here, not taken from the AI, so it always follows
 * one published formula: 30% communication + 40% technical + 30% relevance.
 */
export const overallScore = (f: Pick<AiFeedback, 'communicationScore' | 'technicalScore' | 'relevanceScore'>) =>
  Math.round(0.3 * f.communicationScore + 0.4 * f.technicalScore + 0.3 * f.relevanceScore);