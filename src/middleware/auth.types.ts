import type { SupabaseClient } from '@supabase/supabase-js';

export interface WrappedAuth {
    userId: string;
    db: SupabaseClient;
}