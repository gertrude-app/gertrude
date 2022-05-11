import React from 'react';
import ReactDOM from 'react-dom';
import App from './components/App';

ReactDOM.render(<App />, document.getElementById(`root`));

// Hot Module Replacement (HMR) - Remove this snippet to remove HMR.
// Learn more: https://www.snowpack.dev/concepts/hot-module-replacement
// prettier-ignore
if (undefined /* [snowpack] import.meta.hot */) {
  // @ts-ignore
  undefined /* [snowpack] import.meta.hot */ .accept(); // eslint-disable-line
}
