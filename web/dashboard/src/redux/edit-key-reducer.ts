import { isoFromDateInput } from '@dashboard/lib/dates';

export default function reducer(state: EditKey.State, action: EditKey.Event): void {
  if (action.set === `currentStep` && action.to === `next`) {
    switch (state.currentStep) {
      case `setKeyType`:
        state.currentStep =
          state.keyType === `app` ? `appKey_chooseApp` : `websiteKey_setAddress`;
        return;
      case `websiteKey_setAddress`:
        state.currentStep = `websiteKey_setAppScope`;
        return;
      case `websiteKey_chooseApp`:
      case `appKey_setAddress`: // fallthrough
        state.currentStep = `expiration`;
        return;
      case `appKey_setAppScope`:
        state.currentStep = `expiration`;
        return;
      case `websiteKey_setAppScope`:
        state.currentStep =
          state.addressScope === `singleApp` ? `websiteKey_chooseApp` : `expiration`;
        return;
      case `expiration`:
        state.currentStep = `comment`;
        return;
      default:
        return;
    }
  }

  if (action.set === `currentStep` && action.to === `prev`) {
    switch (state.currentStep) {
      case `appKey_chooseApp`:
        state.currentStep = `setKeyType`;
        return;
      case `websiteKey_setAppScope`:
        state.currentStep = `websiteKey_setAddress`;
        return;
      case `websiteKey_setAddress`:
        state.currentStep = `setKeyType`;
        return;
      case `expiration`:
        if (state.keyType === `website`) {
          state.currentStep =
            state.addressScope === `singleApp`
              ? `websiteKey_chooseApp`
              : `websiteKey_setAppScope`;
        } else {
          state.currentStep =
            state.appScope === `address` ? `appKey_setAddress` : `appKey_setAppScope`;
        }
        return;
      case `comment`:
        state.currentStep = `expiration`;
        return;
      default:
        return;
    }
  }

  switch (action.set) {
    case `keyType`:
      state.keyType = action.to;
      break;

    case `appSlug`:
      state.appSlug = action.to;
      break;

    case `appScope`:
      state.appScope = action.to;
      break;

    case `addressScope`:
      state.addressScope = action.to;
      break;

    case `appIdentificationType`:
      state.appIdentificationType = action.to;
      break;

    case `appBundleId`:
      state.appBundleId = action.to;
      break;

    case `address`:
      state.address = action.to;
      break;

    case `showAdvancedAddressOptions`:
      state.showAdvancedAddressOptions = action.to;
      break;

    case `showAdvancedAddressScopeOptions`:
      state.showAdvancedAddressScopeOptions = action.to;
      if (action.to === false && state.addressScope === `singleApp`) {
        state.addressScope = `webBrowsers`;
      }
      break;

    case `addressType`:
      state.addressType = action.to;
      break;

    case `expirationDate`:
      if (action.to) {
        state.expiration = isoFromDateInput(action.to, state.expiration);
      } else {
        state.expiration = undefined;
      }
      break;

    case `expirationTime`:
      if (state.expiration) {
        const [date] = state.expiration.split(`T`);
        state.expiration = `${date}T${action.to}:00.000Z`;
      }
      break;

    case `comment`:
      state.comment = action.to;
      break;

    default:
      break;
  }
}
