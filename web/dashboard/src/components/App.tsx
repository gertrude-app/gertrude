import React from 'react';
import Button from '@shared/Button';

const App: React.FC = () => (
  <div className="h-screen flex items-center justify-center">
    <h1 className="text-5xl font-bold text-red-800">
      Hello, App! <Button />
    </h1>
  </div>
);

export default App;
