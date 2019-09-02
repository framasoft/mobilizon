export function buildObjectCollection<T, U>(collection: T[] | undefined, builder: (new (p: T) => U)) {
  if (!collection || Array.isArray(collection) === false) return [];

  return collection.map(v => new builder(v));
}
