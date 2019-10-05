// Set the en-US language just in case
export const onBeforeLoad = (window) => Object.defineProperty(window.navigator, 'language', { value: 'en-US' });