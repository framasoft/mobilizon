import { IPicture } from '@/types/picture.model';

export async function buildFileFromIPicture(obj: IPicture | null) {
  if (!obj) return null;

  const response = await fetch(obj.url);
  const blob = await response.blob();

  return new File([blob], obj.name);
}

export function buildFileVariable<T>(file: File | null, name: string, alt?: string) {
  if (!file) return {};

  return {
    [name]: {
      picture: {
        name: file.name,
        alt: alt || file.name,
        file,
      },
    },
  };
}

export function readFileAsync(file: File): Promise<string|ArrayBuffer|null> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => {
      resolve(reader.result);
    };

    reader.onerror = reject;

    reader.readAsBinaryString(file);
  });
}
