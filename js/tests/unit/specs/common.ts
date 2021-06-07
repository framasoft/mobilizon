import { ICurrentUserRole } from "@/types/enums";

export const defaultResolvers = {
  Query: {
    currentUser: (): Record<string, any> => ({
      email: "user@mail.com",
      id: "2",
      role: ICurrentUserRole.USER,
      isLoggedIn: true,
      __typename: "CurrentUser",
    }),
    currentActor: (): Record<string, any> => ({
      id: "67",
      preferredUsername: "someone",
      name: "Personne",
      __typename: "CurrentActor",
    }),
  },
};
