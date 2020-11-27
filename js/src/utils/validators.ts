export function validateEmailField(value: string): boolean | string {
  return value.includes("@") || "Invalid e-mail.";
}

export function validateRequiredField(value: unknown): boolean | string {
  return !!value || "Required.";
}
