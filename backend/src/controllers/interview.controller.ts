import type { Request, Response } from 'express';

import { getAuth } from '../middleware/auth';
import {
  completeInterview,
  createInterview,
  deleteInterview,
  getInterviewDetail,
  getProgress,
  listInterviews,
  submitAnswer,
} from '../services/interview.service';
import { answerSchema, createInterviewSchema, idParam } from '../validation/interview';

export async function list(_req: Request, res: Response) {
  const { db } = getAuth(res);
  res.json({ interviews: await listInterviews(db) });
}

export async function create(req: Request, res: Response) {
  const { db, userId } = getAuth(res);
  const input = createInterviewSchema.parse(req.body);
  res.status(201).json(await createInterview(db, userId, input));
}

export async function detail(req: Request, res: Response) {
  const { db } = getAuth(res);
  res.json(await getInterviewDetail(db, idParam.parse(req.params.id)));
}

export async function answer(req: Request, res: Response) {
  const { db, userId } = getAuth(res);
  const id = idParam.parse(req.params.id);
  const { answer: text } = answerSchema.parse(req.body);
  res.json(await submitAnswer(db, userId, id, text));
}

export async function complete(req: Request, res: Response) {
  const { db, userId } = getAuth(res);
  res.json(await completeInterview(db, userId, idParam.parse(req.params.id)));
}

export async function remove(req: Request, res: Response) {
  const { db } = getAuth(res);
  await deleteInterview(db, idParam.parse(req.params.id));
  res.status(204).end();
}

export async function progress(_req: Request, res: Response) {
  const { db } = getAuth(res);
  res.json(await getProgress(db));
}