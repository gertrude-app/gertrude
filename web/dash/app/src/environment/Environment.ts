import { enumValues } from '@shared/ts-utils';

export enum Mode {
  Dev,
  Staging,
  Prod,
}

export enum OptionalVar {
  TestAdminCreds,
  IsStaging,
}

export enum RequiredVar {
  ApiEndpoint,
  TurnstileSitekey,
}

export interface EnvironmentClient {
  apiEndpoint(): string;
  turnstileSitekey(): string;
  mode(): Mode;
  isDev(): boolean;
  isStaging(): boolean;
  isProd(): boolean;
  requiredVar(varName: RequiredVar): string;
  optionalVar(varName: OptionalVar): string | undefined;
}

export class LiveEnvironment implements EnvironmentClient {
  public constructor() {
    // make it impossible to construct this class without all required vars
    for (const requiredVar of enumValues(RequiredVar)) {
      this.requiredVar(requiredVar);
    }
  }

  public apiEndpoint(): string {
    return this.requiredVar(RequiredVar.ApiEndpoint);
  }

  public turnstileSitekey(): string {
    return this.requiredVar(RequiredVar.TurnstileSitekey);
  }

  public mode(): Mode {
    if (import.meta.env.MODE === `development`) {
      return Mode.Dev;
    } else if (this.optionalVar(OptionalVar.IsStaging) === `true`) {
      return Mode.Staging;
    } else {
      return Mode.Prod;
    }
  }

  public isDev(): boolean {
    return this.mode() === Mode.Dev;
  }

  public isStaging(): boolean {
    return this.mode() === Mode.Staging;
  }

  public isProd(): boolean {
    return this.mode() === Mode.Prod;
  }

  public requiredVar(varName: RequiredVar): string {
    switch (varName) {
      case RequiredVar.ApiEndpoint:
        return requireVar(
          import.meta.env.VITE_API_ENDPOINT,
          RequiredVar.ApiEndpoint,
          `VITE_API_ENDPOINT`,
        );
      case RequiredVar.TurnstileSitekey:
        return requireVar(
          import.meta.env.VITE_TURNSTILE_SITEKEY,
          RequiredVar.TurnstileSitekey,
          `VITE_TURNSTILE_SITEKEY`,
        );
      default:
        throw new Error(`Unhandled check for required var \`${RequiredVar[varName]}\``);
    }
  }

  public optionalVar(varName: OptionalVar): string | undefined {
    switch (varName) {
      case OptionalVar.TestAdminCreds:
        return import.meta.env[`VITE_TEST_ADMIN_CREDS`];
      case OptionalVar.IsStaging:
        return import.meta.env[`VITE_IS_STAGING`];
    }
  }
}

// helpers

function requireVar(
  value: string | undefined,
  varName: RequiredVar,
  envVar: string,
): string {
  if (value === undefined) {
    throw new Error(
      `Environment variable \`${RequiredVar[varName]}\` (\`${envVar}\`) is not set`,
    );
  }
  return value;
}
