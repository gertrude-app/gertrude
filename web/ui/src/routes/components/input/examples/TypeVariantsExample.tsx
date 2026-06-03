import React, { useState } from 'react';
import Input from '#/components/ui/Input';

const TypeVariantsExample: React.FC = () => {
  const [text, setText] = useState(`Family MacBook`);
  const [email, setEmail] = useState(``);
  const [password, setPassword] = useState(`super-secret`);
  const [number, setNumber] = useState(``);
  const [time, setTime] = useState(`20:30`);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl gap-5 sm:grid-cols-2">
        <Input
          type="text"
          label="Text"
          placeholder="Device name"
          value={text}
          setValue={setText}
        />
        <div className="sm:pt-5">
          <Input
            type="email"
            name="email"
            autoComplete="email"
            placeholder="you@example.com"
            value={email}
            setValue={setEmail}
          />
        </div>
        <Input
          type="password"
          name="password"
          autoComplete="current-password"
          label="Password"
          placeholder="Password"
          value={password}
          setValue={setPassword}
        />
        <div className="sm:pt-5">
          <Input type="number" placeholder="7" value={number} setValue={setNumber} />
        </div>
        <Input type="time" label="Time" value={time} setValue={setTime} />
      </div>
    </div>
  );
};

export default TypeVariantsExample;
