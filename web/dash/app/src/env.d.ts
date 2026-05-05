/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_ENDPOINT: string;
  readonly VITE_TURNSTILE_SITEKEY: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
