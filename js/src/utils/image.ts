import { IMedia } from "@/types/media.model";

export async function buildFileFromIMedia(
  obj: IMedia | null | undefined
): Promise<File | null> {
  if (!obj) return Promise.resolve(null);

  const response = await fetch(obj.url);
  const blob = await response.blob();

  return new File([blob], obj.name);
}

export function buildFileVariable(
  file: File | null,
  name: string,
  alt?: string
): Record<string, unknown> {
  if (!file) return {};

  return {
    [name]: {
      media: {
        name: file.name,
        alt: alt || file.name,
        file,
      },
    },
  };
}

export function readFileAsync(
  file: File
): Promise<string | ArrayBuffer | null> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => {
      resolve(reader.result);
    };

    reader.onerror = reject;

    reader.readAsBinaryString(file);
  });
}
