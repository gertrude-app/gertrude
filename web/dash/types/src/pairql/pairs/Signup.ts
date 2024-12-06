// auto-generated, do not edit

export namespace Signup {
  export interface Input {
    email: string;
    password: string;
    gclid?: string;
    abTestVariant?: string;
  }

  export interface Output {
    admin?: {
      adminId: UUID;
      token: UUID;
    };
  }
}
