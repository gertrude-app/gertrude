import type { AdminData } from './types';

export default async function getAdminData(): Promise<AdminResult> {
  const res = await fetch(`${process.env.API_URL}/pairql/super-admin/QueryAdmins`, {
    method: `POST`,
    headers: {
      'X-SuperAdminToken': process.env.SUPER_ADMIN_TOKEN ?? ``,
    },
    cache: `no-store`,
  });
  if (res.status === 200) {
    return {
      success: true,
      data: await res.json(),
    };
  }

  const json = await res.json();

  return {
    success: false,
    error: json.debugMessage || `Unknown error`,
  };
}

export type AdminResult =
  | { success: true; data: AdminData[] }
  | { success: false; error: string };
