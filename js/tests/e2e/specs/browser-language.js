// Set the en-US language just in case
// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export default function (window) {
  Object.defineProperty(window.navigator, "language", { value: "en-US" });
}
