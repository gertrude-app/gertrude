import React from 'react';
import TimeSeriesGraph from './TimeSeriesGraph';

interface Signup {
  date: string;
  status: string;
  email: string;
}

interface SignupGraphProps {
  signups: Signup[];
}

const SignupGraph: React.FC<SignupGraphProps> = ({ signups }) => {
  const items = signups.map((signup) => ({
    date: signup.date,
    status: signup.status,
    label: signup.email,
  }));

  return (
    <TimeSeriesGraph
      items={items}
      itemLabel="new signup"
      gradient="violet"
      statusConfig={{
        isSuccess: (status) => status === `full`,
        isWarning: (status) => status === `light`,
      }}
    />
  );
};

export default SignupGraph;
