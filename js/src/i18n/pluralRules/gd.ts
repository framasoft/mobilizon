export default function (choice: number): number {
  if (choice === 1 || choice === 11) {
    return 0;
  }

  if (choice === 2 || choice === 12) {
    return 1;
  }

  return choice > 0 && choice < 20 ? 2 : 3;
}
