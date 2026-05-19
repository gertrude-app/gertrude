export type Device =
  | {
      type: 'mac';
      name?: string;
      macOSVersion: string;
      modelName: string;
      online: boolean;
    }
  | {
      type: 'iphone' | 'ipad';
      iOSVersion: string;
      modelName: string;
    };

export type Child = {
  name: string;
  devices: Device[];
};

const familyIpad: Device = {
  type: 'ipad',
  iOSVersion: '18.4',
  modelName: 'iPad (10th generation)',
};

const schoolMacBook: Device = {
  type: 'mac',
  macOSVersion: '15.4',
  modelName: 'MacBook Air 13-inch, M2',
  online: true,
};

const kitchenIMac: Device = {
  type: 'mac',
  name: 'Kitchen iMac',
  macOSVersion: '14.7',
  modelName: 'iMac 24-inch, M1',
  online: false,
};

export const mockChildren: Child[] = [
  {
    name: 'Jimmy',
    devices: [familyIpad, schoolMacBook],
  },
  {
    name: 'Sally',
    devices: [
      {
        type: 'iphone',
        iOSVersion: '18.3',
        modelName: 'iPhone 14',
      },
      familyIpad,
      kitchenIMac,
    ],
  },
  {
    name: 'Franny',
    devices: [],
  },
  {
    name: 'Theo',
    devices: [
      {
        type: 'ipad',
        iOSVersion: '17.7',
        modelName: 'iPad mini (6th generation)',
      },
    ],
  },
  {
    name: 'Maggie',
    devices: [
      {
        type: 'iphone',
        iOSVersion: '18.4',
        modelName: 'iPhone SE (3rd generation)',
      },
      schoolMacBook,
      kitchenIMac,
    ],
  },
];
