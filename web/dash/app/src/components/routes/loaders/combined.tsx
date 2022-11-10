import type { EntityLoader } from './loader-types';
import UnexpectedError from '../../UnexpectedError';

export function useCombinedLoaders<
  ArgsA extends any[],
  EntityA,
  ArgsB extends any[],
  EntityB,
>(
  useLoaderA: (...args: ArgsA) => EntityLoader<EntityA>,
  argsA: ArgsA,
  useLoaderB: (...args: ArgsB) => EntityLoader<EntityB>,
  argsB: ArgsB,
): EntityLoader<[EntityA, EntityB]> {
  const loaderA = useLoaderA(...argsA);
  const loaderB = useLoaderB(...argsB);

  if (loaderA.state === `resolved` && loaderB.state === `resolved`) {
    return {
      state: `resolved`,
      entity: [loaderA.entity, loaderB.entity],
    };
  }

  if (loaderA.state === `resolved` && loaderB.state === `unresolved`) {
    return loaderB;
  }

  if (loaderB.state === `resolved` && loaderA.state === `unresolved`) {
    return loaderA;
  }

  if (loaderA.state === `unresolved` && loaderA.isError) {
    return loaderA;
  }

  if (loaderB.state === `unresolved` && loaderB.isError) {
    return loaderB;
  }

  if (loaderA.state === `unresolved`) {
    return loaderA;
  } else if (loaderB.state === `unresolved`) {
    return loaderB;
  } else {
    return {
      state: `unresolved`,
      element: <UnexpectedError id="82285d7e" />,
    };
  }
}
