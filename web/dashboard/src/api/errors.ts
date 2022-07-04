export enum ErrorType {
  Unknown = `UNKNOWN`, // @TODO
}

export type DashboardError = {
  type: ErrorType;
  detail?: string;
  userMsg?: string;
};
