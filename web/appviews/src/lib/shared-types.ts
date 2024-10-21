// begin codegen
export type FilterState =
  | { case: 'suspended'; resuming: string }
  | { case: 'downtimePaused'; resuming: string } // added manually
  | { case: 'off' }
  | { case: 'on' };

export type AdminAccountStatus = 'active' | 'needsAttention' | 'inactive';
// end codegen
