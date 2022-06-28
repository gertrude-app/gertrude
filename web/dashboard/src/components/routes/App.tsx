import React from 'react';
import { Link } from 'react-router-dom';

const App: React.FC = () => {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center">
      <h1 className="font-inter text-4xl mb-3">Gertrude</h1>
      <Link
        to="/join-waitlist"
        className="text-blue-400 hover:text-blue-500 transition duration-100"
      >
        Join the waitlist
      </Link>
    </div>
  );
};

export default App;
