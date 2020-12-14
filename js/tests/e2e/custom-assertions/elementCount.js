export default class ElementCount {
  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  constructor(selector, count) {
    this.message = `Testing if element <${selector}> has count: ${count}`;
    this.expected = count;
    this.pass = (val) => val === count;
    this.value = (res) => res.value;
    function evaluator(_selector) {
      return document.querySelectorAll(_selector).length;
    }
    this.command = (cb) => this.api.execute(evaluator, [selector], cb);
  }
}
