async function asyncForEach(
  array: Array<any>,
  callback: (arg0: any, arg1: number, arg2: Array<any>) => void
): Promise<void> {
  for (let index = 0; index < array.length; index += 1) {
    callback(array[index], index, array);
  }
}

export { asyncForEach };
