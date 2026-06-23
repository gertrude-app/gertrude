import React from 'react';
import type {
  MockDb,
  PersonIosSettingsConfiguration,
  PersonMacSettingsConfiguration,
} from './types';
import { initialMockDb } from './seed';

export type MockDataAction =
  | { type: `person.updateName`; id: string; name: string }
  | { type: `person.delete`; id: string }
  | { type: `unlockRequest.resolve`; id: string }
  | { type: `suspensionRequest.resolve`; id: string }
  | { type: `activity.toggleFlag`; id: string }
  | { type: `activity.delete`; id: string }
  | { type: `activity.deleteForPerson`; personId: string }
  | {
      type: `macSettings.patch`;
      personId: string;
      patch: Partial<PersonMacSettingsConfiguration>;
    }
  | {
      type: `iosSettings.patch`;
      personId: string;
      patch: Partial<PersonIosSettingsConfiguration>;
    };

type MockDataStore = {
  db: MockDb;
  dispatch: React.Dispatch<MockDataAction>;
};

const MockDataContext = React.createContext<MockDataStore | null>(null);

function mockDataReducer(db: MockDb, action: MockDataAction): MockDb {
  switch (action.type) {
    case `person.updateName`:
      return {
        ...db,
        people: db.people.map((person) =>
          person.id === action.id ? { ...person, name: action.name } : person,
        ),
      };
    case `person.delete`:
      return {
        ...db,
        people: db.people.filter((person) => person.id !== action.id),
        devices: db.devices.filter((device) => device.personId !== action.id),
        activity: db.activity.filter((activity) => activity.personId !== action.id),
        unlockRequests: db.unlockRequests.filter(
          (request) => request.personId !== action.id,
        ),
        suspensionRequests: db.suspensionRequests.filter(
          (request) => request.personId !== action.id,
        ),
        macSettings: db.macSettings.filter((settings) => settings.personId !== action.id),
        iosSettings: db.iosSettings.filter((settings) => settings.personId !== action.id),
        installedMacApps: db.installedMacApps.filter((app) => app.personId !== action.id),
      };
    case `unlockRequest.resolve`:
      return {
        ...db,
        unlockRequests: db.unlockRequests.filter((request) => request.id !== action.id),
      };
    case `suspensionRequest.resolve`:
      return {
        ...db,
        suspensionRequests: db.suspensionRequests.filter(
          (request) => request.id !== action.id,
        ),
      };
    case `activity.toggleFlag`:
      return {
        ...db,
        activity: db.activity.map((activity) =>
          activity.id === action.id
            ? { ...activity, flagged: !activity.flagged }
            : activity,
        ),
      };
    case `activity.delete`:
      return {
        ...db,
        activity: db.activity.map((activity) =>
          activity.id === action.id ? { ...activity, deleted: true } : activity,
        ),
      };
    case `activity.deleteForPerson`:
      return {
        ...db,
        activity: db.activity.map((activity) =>
          activity.personId === action.personId
            ? { ...activity, deleted: true }
            : activity,
        ),
      };
    case `macSettings.patch`:
      return {
        ...db,
        macSettings: db.macSettings.map((settings) =>
          settings.personId === action.personId
            ? { ...settings, ...action.patch }
            : settings,
        ),
      };
    case `iosSettings.patch`:
      return {
        ...db,
        iosSettings: db.iosSettings.map((settings) =>
          settings.personId === action.personId
            ? { ...settings, ...action.patch }
            : settings,
        ),
      };
  }
}

export const MockDataProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [db, dispatch] = React.useReducer(mockDataReducer, initialMockDb);
  const value = React.useMemo(() => ({ db, dispatch }), [db]);

  return <MockDataContext.Provider value={value}>{children}</MockDataContext.Provider>;
};

export function useMockData(): MockDataStore {
  const store = React.useContext(MockDataContext);

  if (!store) {
    throw new Error(`useMockData must be used inside MockDataProvider`);
  }

  return store;
}

export function useMockDataSelector<T>(selector: (db: MockDb) => T): T {
  const { db } = useMockData();
  return selector(db);
}
