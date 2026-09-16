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
exports.CreatePlacementTestDto = exports.QueryPpdbDto = exports.UpdatePendaftaranDto = exports.LookupPpdbDto = exports.DaftarPpdbDto = void 0;
const class_transformer_1 = require("class-transformer");
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
const is_url_or_data_uri_validator_1 = require("../../common/validators/is-url-or-data-uri.validator");
class DaftarPpdbDto {
}
exports.DaftarPpdbDto = DaftarPpdbDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)({ message: 'Kode pondok wajib diisi' }),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "kodeTenant", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)({ message: 'Nama lengkap wajib diisi' }),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "nama", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)({ message: 'Jenis kelamin wajib diisi' }),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "jenisKelamin", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "tanggalLahir", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "asalSekolah", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "noHp", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "email", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "alamat", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "jalur", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, is_url_or_data_uri_validator_1.IsUrlOrDataUri)(),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "fotoUrl", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, is_url_or_data_uri_validator_1.IsUrlOrDataUri)(),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "kartuKeluargaUrl", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, is_url_or_data_uri_validator_1.IsUrlOrDataUri)(),
    __metadata("design:type", String)
], DaftarPpdbDto.prototype, "aktaLahirUrl", void 0);
class LookupPpdbDto {
}
exports.LookupPpdbDto = LookupPpdbDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)({ message: 'Kode pondok wajib diisi' }),
    __metadata("design:type", String)
], LookupPpdbDto.prototype, "kode", void 0);
class UpdatePendaftaranDto {
}
exports.UpdatePendaftaranDto = UpdatePendaftaranDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(client_1.StatusPendaftaran, { message: 'Status tidak valid' }),
    __metadata("design:type", String)
], UpdatePendaftaranDto.prototype, "status", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdatePendaftaranDto.prototype, "catatan", void 0);
class QueryPpdbDto {
}
exports.QueryPpdbDto = QueryPpdbDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], QueryPpdbDto.prototype, "status", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], QueryPpdbDto.prototype, "q", void 0);
class CreatePlacementTestDto {
}
exports.CreatePlacementTestDto = CreatePlacementTestDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreatePlacementTestDto.prototype, "mapelId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    (0, class_validator_1.Max)(100),
    __metadata("design:type", Number)
], CreatePlacementTestDto.prototype, "nilai", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreatePlacementTestDto.prototype, "hasil", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreatePlacementTestDto.prototype, "catatan", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreatePlacementTestDto.prototype, "tanggal", void 0);
//# sourceMappingURL=ppdb.dto.js.map