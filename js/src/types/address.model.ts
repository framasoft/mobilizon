export interface IAddress {
  id?: number;
  description: string;
  floor: string;
  street: string;
  locality: string;
  postalCode: string;
  region: string;
  country: string;
  geom?: string;
  url?: string;
  originId?: string;
}

export class Address implements IAddress {
  country: string = '';
  description: string = '';
  floor: string = '';
  locality: string = '';
  postalCode: string = '';
  region: string = '';
  street: string = '';
}
