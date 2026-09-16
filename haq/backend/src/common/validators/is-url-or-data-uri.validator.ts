import { registerDecorator, ValidationOptions } from 'class-validator';

// 2MB file mentah -> base64 membengkak ~4/3x + prefix "data:image/...;base64,"
// jadi batas string base64-nya ~2.8 juta karakter, bukan 2 juta
const MAX_DATA_URI_LENGTH = 2_800_000;

export function IsUrlOrDataUri(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'IsUrlOrDataUri',
      target: object.constructor,
      propertyName,
      options: {
        message:
          'Harus berupa URL yang valid, atau gambar/berkas (base64) berukuran maksimal 2MB',
        ...validationOptions,
      },
      validator: {
        validate(value: unknown) {
          if (typeof value !== 'string' || value.length === 0) return true;
          if (value.startsWith('data:')) return value.length < MAX_DATA_URI_LENGTH;
          try {
            new URL(value);
            return true;
          } catch {
            return false;
          }
        },
      },
    });
  };
}