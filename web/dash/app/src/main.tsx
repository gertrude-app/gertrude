import React from 'react';
import ReactDOM from 'react-dom/client';
import { Toaster } from 'react-hot-toast';
import { BrowserRouter } from 'react-router-dom';
import { Provider } from 'react-redux';
import { store } from './redux/store';
import App from './App';

// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
ReactDOM.createRoot(document.getElementById(`root`)!).render(
  <Provider store={store}>
    <Toaster position="top-right" />
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </Provider>,
);
