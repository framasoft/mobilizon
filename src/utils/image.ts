import { IMedia, IModifiableMedia } from "@/types/media.model";
import { ref, watch } from "vue";

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

export function readFileAsync(file: File): Promise<ArrayBuffer | null> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => {
      resolve(reader.result as ArrayBuffer);
    };

    reader.onerror = reject;

    reader.readAsArrayBuffer(file);
  });
}

export async function fileHash(file: File): Promise<string | null> {
  const data = await readFileAsync(file);
  if (data === null) return null;
  const hash = await crypto.subtle.digest("SHA-1", data);
  const b64Hash = btoa(
    Array.from(new Uint8Array(hash))
      .map((b) => String.fromCharCode(b))
      .join("")
  );
  return b64Hash;
}

export function initWrappedMedia(): IModifiableMedia {
  return {
    file: ref<File | null>(null),
    firstHash: null,
    hash: null,
  };
}

export async function loadWrappedMedia(
  modifiableMedia: IModifiableMedia,
  media: IMedia | null
) {
  watch(modifiableMedia.file, async () => {
    if (modifiableMedia.file.value) {
      modifiableMedia.hash = await fileHash(modifiableMedia.file.value);
    } else {
      modifiableMedia.hash = null;
    }
  });
  try {
    modifiableMedia.file.value = await buildFileFromIMedia(media);
  } catch (e) {
    console.error("catched error while building media", e);
  }
  if (modifiableMedia.file.value) {
    modifiableMedia.firstHash = await fileHash(modifiableMedia.file.value);
  }
}

export function asMediaInput(
  mmedia: IModifiableMedia,
  name: string,
  fallbackId: number
): any {
  const ret = {
    [name]: {},
  };
  if (mmedia.file.value) {
    if (mmedia.firstHash != mmedia.hash) {
      ret[name] = {
        media: {
          name: mmedia.file.value?.name,
          alt: "",
          file: mmedia.file.value,
        },
      };
    } else {
      ret[name] = {
        mediaId: fallbackId,
      };
    }
  }
  return ret;
}
