import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';

ReactDOM.createRoot(document.getElementById(`root`)!).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>,
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
