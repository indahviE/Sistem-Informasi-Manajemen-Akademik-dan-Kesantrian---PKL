"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RejectTenantDto = exports.ApproveTenantDto = exports.UpdateBrandingDto = exports.SignupTenantDto = void 0;
const class_validator_1 = require("class-validator");
const class_validator_2 = require("class-validator");
function IsUrlOrDataUri(validationOptions) {
    return function (object, propertyName) {
        (0, class_validator_2.registerDecorator)({
            name: 'IsUrlOrDataUri',
            target: object.constructor,
            propertyName,
            options: {
                message: 'Logo harus berupa URL atau data URI base64',
                ...validationOptions,
            },
            validator: {
                validate(value) {
                    if (typeof value !== 'string' || value.length === 0)
                        return true;
                    if (value.startsWith('data:'))
                        return value.length < 2_000_000;
                    try {
                        new URL(value);
                        return true;
                    }
                    catch {
                        return false;
                    }
                },
            },
        });
    };
}
class SignupTenantDto {
}
exports.SignupTenantDto = SignupTenantDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)({ message: 'Nama pondok wajib diisi' }),
    __metadata("design:type", String)
], SignupTenantDto.prototype, "namaPondok", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)({ message: 'Kode tenant wajib diisi' }),
    (0, class_validator_1.Matches)(/^[a-z0-9-]+$/, {
        message: 'Kode tenant hanya boleh huruf kecil, angka, dan tanda strip (-)',
    }),
    __metadata("design:type", String)
], SignupTenantDto.prototype, "kodeTenant", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    IsUrlOrDataUri(),
    __metadata("design:type", String)
], SignupTenantDto.prototype, "logoUrl", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)({ message: 'Nama admin awal wajib diisi' }),
    __metadata("design:type", String)
], SignupTenantDto.prototype, "adminNama", void 0);
__decorate([
    (0, class_validator_1.IsEmail)({}, { message: 'Email admin tidak valid' }),
    __metadata("design:type", String)
], SignupTenantDto.prototype, "adminEmail", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(6, { message: 'Password minimal 6 karakter' }),
    __metadata("design:type", String)
], SignupTenantDto.prototype, "adminPassword", void 0);
class UpdateBrandingDto {
}
exports.UpdateBrandingDto = UpdateBrandingDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateBrandingDto.prototype, "namaPondok", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    IsUrlOrDataUri(),
    __metadata("design:type", String)
], UpdateBrandingDto.prototype, "logoUrl", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.Matches)(/^#[0-9a-fA-F]{6}$/, { message: 'Warna tema harus format hex (mis. #10b981)' }),
    __metadata("design:type", String)
], UpdateBrandingDto.prototype, "warnaTema", void 0);
class ApproveTenantDto {
}
exports.ApproveTenantDto = ApproveTenantDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], ApproveTenantDto.prototype, "tenantId", void 0);
class RejectTenantDto {
}
exports.RejectTenantDto = RejectTenantDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], RejectTenantDto.prototype, "tenantId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], RejectTenantDto.prototype, "alasan", void 0);
//# sourceMappingURL=tenant.dto.js.map