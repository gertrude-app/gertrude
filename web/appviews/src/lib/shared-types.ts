// begin codegen
export type FilterState =
  | { case: 'suspended'; resuming: string }
  | { case: 'downtime'; ending: string }
  | { case: 'downtimePaused'; resuming: string }
  | { case: 'off' }
  | { case: 'on' };

export type AdminAccountStatus = 'active' | 'needsAttention' | 'inactive';
// end codegen
