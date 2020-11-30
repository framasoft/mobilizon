async function asyncForEach(
  array: Array<any>,
  callback: (arg0: any, arg1: number, arg2: Array<any>) => any
): Promise<void> {
  for (let index = 0; index < array.length; index += 1) {
    // eslint-disable-next-line no-await-in-loop
    await callback(array[index], index, array);
  }
}

export { asyncForEach };
