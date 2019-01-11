export function validateEmail(value: string) {
  return value.includes('@') || 'Invalid e-mail.';
}

export function validateRequiredField(value: any) {
  return !!value || 'Required.';
}
