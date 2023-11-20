/// <reference types="histoire/vue" />

/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SERVER_URL: string;
  readonly VITE_HISTOIRE_ENV: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
