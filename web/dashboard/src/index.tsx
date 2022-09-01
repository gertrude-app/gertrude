import React from 'react';
import ReactDOM from 'react-dom/client';
import { Toaster } from 'react-hot-toast';
import { BrowserRouter } from 'react-router-dom';
import { Provider } from 'react-redux';
import { store } from './redux/store';
import App from './App';

ReactDOM.createRoot(document.getElementById(`root`)!).render(
  <React.StrictMode>
    <Provider store={store}>
      <Toaster position="top-right" />
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </Provider>
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
