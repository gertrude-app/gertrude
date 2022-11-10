export type EntityLoader<Entity> =
  | { state: 'resolved'; entity: Entity }
  | { state: 'unresolved'; isError?: boolean; element: JSX.Element };
