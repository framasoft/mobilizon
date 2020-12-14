// eslint-disable-next-line @typescript-eslint/no-var-requires
const vueJest = require("vue-jest/lib/template-compiler");

module.exports = {
  process(content) {
    const { render } = vueJest({
      content,
      attrs: {
        functional: false,
      },
    });

    return `module.exports = { render: ${render} }`;
  },
};
