import random from "lodash/random";

export const randomGradient = (): string => {
  const direction = [
    "bg-gradient-to-t",
    "bg-gradient-to-tr",
    "bg-gradient-to-r",
    "bg-gradient-to-br",
    "bg-gradient-to-b",
    "bg-gradient-to-bl",
    "bg-gradient-to-l",
    "bg-gradient-to-tl",
  ];
  const gradients = [
    "from-pink-500 via-red-500 to-yellow-500",
    "from-green-400 via-blue-500 to-purple-600",
    "from-pink-400 via-purple-300 to-indigo-400",
    "from-yellow-300 via-yellow-500 to-yellow-700",
    "from-yellow-300 via-green-400 to-green-500",
    "from-red-400 via-red-600 to-yellow-400",
    "from-green-400 via-green-500 to-blue-700",
    "from-yellow-400 via-yellow-500 to-yellow-700",
    "from-green-300 via-green-400 to-purple-700",
  ];
  return `${direction[random(0, direction.length - 1)]} ${
    gradients[random(0, gradients.length - 1)]
  }`;
};
