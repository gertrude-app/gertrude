import { enumValues } from '../lib/typesafe';

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
  GraphQLEndpoint,
}

export interface EnvironmentClient {
  graphQLEndpoint(): string;
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

  public graphQLEndpoint(): string {
    return this.requiredVar(RequiredVar.GraphQLEndpoint);
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
      case RequiredVar.GraphQLEndpoint:
        return requireVar(
          import.meta.env.VITE_GRAPHQL_ENDPOINT,
          RequiredVar.GraphQLEndpoint,
          `VITE_GRAPHQL_ENDPOINT`,
        );
      default:
        throw new Error(`Unhandled check for required var \`${RequiredVar[varName]}\``);
    }
  }

  public optionalVar(varName: OptionalVar): string | undefined {
    switch (varName) {
      case OptionalVar.TestAdminCreds:
        return import.meta.env.VITE_TEST_ADMIN_CREDS;
      case OptionalVar.IsStaging:
        return import.meta.env.VITE_IS_STAGING;
    }
  }
}

export class ThrowingEnvironment implements EnvironmentClient {
  public graphQLEndpoint(): string {
    throw new Error(`EnvironmentClient.graphQLEndpoint() not implemented.`);
  }
  public mode(): Mode {
    throw new Error(`EnvironmentClient.mode() not implemented.`);
  }
  public isDev(): boolean {
    throw new Error(`EnvironmentClient.isDev() not implemented.`);
  }
  public isStaging(): boolean {
    throw new Error(`EnvironmentClient.isStaging() not implemented.`);
  }
  public isProd(): boolean {
    throw new Error(`EnvironmentClient.isProd() not implemented.`);
  }
  public requiredVar(_varName: RequiredVar): string {
    throw new Error(`EnvironmentClient.requiredVar() not implemented.`);
  }
  public optionalVar(_varName: OptionalVar): string | undefined {
    throw new Error(`EnvironmentClient.optionalVar() not implemented.`);
  }
}

export class NoopEnvironment implements EnvironmentClient {
  public graphQLEndpoint(): string {
    return ``;
  }
  public mode(): Mode {
    return Mode.Dev;
  }
  public isDev(): boolean {
    return true;
  }
  public isStaging(): boolean {
    return false;
  }
  public isProd(): boolean {
    return false;
  }
  public requiredVar(_varName: RequiredVar): string {
    return ``;
  }
  public optionalVar(_varName: OptionalVar): string | undefined {
    return undefined;
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
