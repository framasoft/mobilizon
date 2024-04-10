import { useExportFormats, useUploadLimits } from "./apollo/config";

export const useHost = (): string => {
  return window.location.hostname;
};

export const useDefaultMaxSize = (): number | undefined => {
  const { uploadLimits } = useUploadLimits();

  return uploadLimits.value?.default;
};

export const useAvatarMaxSize = (): number | undefined => {
  const { uploadLimits } = useUploadLimits();

  return uploadLimits.value?.avatar;
};

export const useBannerMaxSize = (): number | undefined => {
  const { uploadLimits } = useUploadLimits();

  return uploadLimits.value?.banner;
};

export const useParticipantsExportFormats = () => {
  const { exportFormats } = useExportFormats();
  return exportFormats.value?.eventParticipants;
};
