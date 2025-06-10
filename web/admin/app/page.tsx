import type { NextPage } from 'next';
import AppVersionBlock from '@/components/AppVersionBlock';
import OnboardingSuccessStatBlock from '@/components/OnboardingSuccessStatBlock';
import OverallStatsBlock from '@/components/OverallStatsBlock';
import SignupGraph from '@/components/SignupGraph';
import getAdminData from '@/lib/get-data';

const Home: NextPage = async () => {
  const adminData = await getAdminData();
  if (!adminData.success) {
    return <pre>{adminData.error}</pre>;
  }
  return (
    <main className="p-12 flex flex-col gap-8">
      <h1 className="font-semibold text-4xl">Gertrude analytics</h1>
      <OverallStatsBlock admins={adminData.data} />
      <SignupGraph data={adminData.data} />
      <OnboardingSuccessStatBlock admins={adminData.data} />
      <div className="flex gap-8">
        <AppVersionBlock admins={adminData.data} type="app" key="app" />
        <AppVersionBlock admins={adminData.data} type="filter" key="filter" />
      </div>
    </main>
  );
};

export default Home;
