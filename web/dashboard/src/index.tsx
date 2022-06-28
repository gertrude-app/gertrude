import React from 'react';
import ReactDOM from 'react-dom';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import App from './components/routes/App';
import JoinWaitlist from './components/routes/JoinWaitlist';

ReactDOM.render(
  <BrowserRouter>
    <Routes>
      <Route path="/" element={<App />} />
      <Route path="/join-waitlist" element={<JoinWaitlist />} />
    </Routes>
  </BrowserRouter>,
  document.getElementById(`root`),
);

// Hot Module Replacement (HMR) - Remove this snippet to remove HMR.
// Learn more: https://www.snowpack.dev/concepts/hot-module-replacement
// prettier-ignore
// eslint-disable-next-line no-constant-condition
if (undefined /* [snowpack] import.meta.hot */) {
  // @ts-ignore
  undefined /* [snowpack] import.meta.hot */
    .accept(); // eslint-disable-line
}
