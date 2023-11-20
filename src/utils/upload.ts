/**
 * Async function to upload a file
 */
export function listenFileUpload(): Promise<File> {
  return new Promise((resolve, reject) => {
    const inputElement = document.createElement("input");
    inputElement.type = "file";
    inputElement.onchange = () => {
      if (inputElement.files && inputElement.files.length > 0) {
        resolve(inputElement.files[0]);
      }
    };

    inputElement.onerror = reject;
    inputElement.click();
  });
}

/**
 * Async function to upload a file
 */
export function listenFileUploads(): Promise<FileList> {
  return new Promise((resolve, reject) => {
    const inputElement = document.createElement("input");
    inputElement.type = "file";
    inputElement.multiple = true;
    inputElement.onchange = () => {
      if (inputElement.files && inputElement.files.length > 0) {
        resolve(inputElement.files);
      }
    };

    inputElement.onerror = reject;
    inputElement.click();
  });
}
