export interface ISentryConfiguration {
  dsn: string;
  organization?: string;
  project?: string;
  host?: string;
  tracesSampleRate: number;
}
