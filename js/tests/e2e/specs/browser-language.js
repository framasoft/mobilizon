// Set the en-US language just in case
export default function (window) {
  Object.defineProperty(window.navigator, "language", { value: "en-US" });
}
