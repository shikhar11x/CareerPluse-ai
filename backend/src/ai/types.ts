/** Provider-independent AI interface. Swap providers by implementing AiProvider. */
export interface ChatTurn {
  role: 'user' | 'model';
  text: string;
}

export interface GenerateRequest {
  system: string;
  turns: ChatTurn[];
  /** Ask the model to answer with a JSON document. */
  json?: boolean;
  temperature?: number;
  maxOutputTokens?: number;
}

export interface AiProvider {
  generate(req: GenerateRequest): Promise<string>;
}