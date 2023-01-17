import { expect, it, describe } from 'vitest';
import { editable, Query, Req } from '../../../redux/helpers';
import { makeState } from '../../../redux/__tests__/test-helpers';
import { queryProps } from '../AdminProfile';

describe(`Profile.queryProps`, () => {
  it(`handles determining method deletability correctly`, () => {
    const state = makeState((state) => {
      state.admin.profileRequest = Req.succeed({
        email: `blob@blob.com`,
        subscriptionStatus: `trialing`,
      });

      state.admin.notificationMethods = {
        verifiedMethod1: {
          type: `VerifiedEmailMethod`,
          value: {
            id: `verifiedMethod1`,
            email: `blob@blob.com`, // <-- required email
          },
        },
        verifiedMethod2: {
          type: `VerifiedTextMethod`,
          value: {
            id: `verifiedMethod2`,
            phoneNumber: `7`, // <-- used by notification, not deletable
          },
        },
        verifiedMethod3: {
          type: `VerifiedTextMethod`,
          value: {
            id: `verifiedMethod3`,
            phoneNumber: `8`, // <-- should be deletable
          },
        },
      };
      state.admin.notifications = {
        notification1: {
          editing: false,
          ...editable({
            id: `notification1`,
            methodId: `verifiedMethod2`, // <-- makes method 2 not deletable
            trigger: `unlockRequestSubmitted`,
          }),
        },
      };
    });

    const [query] = queryProps((() => {}) as any)(state);
    expect(Query.props(query)?.methods.map((m) => m.deletable)).toEqual([
      false,
      false,
      true,
    ]);
  });
});
