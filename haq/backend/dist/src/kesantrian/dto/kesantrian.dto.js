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
exports.QueryKesantrianDto = exports.CreateTataTertibDto = exports.CreateKunjunganDto = exports.CreateKesehatanDto = exports.UpdatePerizinanDto = exports.CreatePerizinanDto = exports.UpdatePelanggaranDto = exports.CreatePelanggaranDto = void 0;
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
class CreatePelanggaranDto {
}
exports.CreatePelanggaranDto = CreatePelanggaranDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreatePelanggaranDto.prototype, "santriId", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreatePelanggaranDto.prototype, "jenisPelanggaran", void 0);
__decorate([
    (0, class_validator_1.IsInt)({ message: 'Poin harus angka' }),
    __metadata("design:type", Number)
], CreatePelanggaranDto.prototype, "poin", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreatePelanggaranDto.prototype, "tanggal", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreatePelanggaranDto.prototype, "pelaporId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreatePelanggaranDto.prototype, "tindakLanjut", void 0);
class UpdatePelanggaranDto {
}
exports.UpdatePelanggaranDto = UpdatePelanggaranDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdatePelanggaranDto.prototype, "jenisPelanggaran", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], UpdatePelanggaranDto.prototype, "poin", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdatePelanggaranDto.prototype, "tindakLanjut", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdatePelanggaranDto.prototype, "status", void 0);
class CreatePerizinanDto {
}
exports.CreatePerizinanDto = CreatePerizinanDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreatePerizinanDto.prototype, "santriId", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.JenisPerizinan, { message: 'Jenis perizinan tidak valid' }),
    __metadata("design:type", String)
], CreatePerizinanDto.prototype, "jenis", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreatePerizinanDto.prototype, "tanggalKeluar", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreatePerizinanDto.prototype, "tanggalKembali", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreatePerizinanDto.prototype, "alasan", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreatePerizinanDto.prototype, "catatan", void 0);
class UpdatePerizinanDto {
}
exports.UpdatePerizinanDto = UpdatePerizinanDto;
__decorate([
    (0, class_validator_1.IsEnum)(client_1.StatusApproval, { message: 'Status approval tidak valid' }),
    __metadata("design:type", String)
], UpdatePerizinanDto.prototype, "statusApproval", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdatePerizinanDto.prototype, "disetujuiOleh", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], UpdatePerizinanDto.prototype, "tanggalKembali", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdatePerizinanDto.prototype, "catatan", void 0);
class CreateKesehatanDto {
}
exports.CreateKesehatanDto = CreateKesehatanDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateKesehatanDto.prototype, "santriId", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateKesehatanDto.prototype, "keluhan", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateKesehatanDto.prototype, "diagnosa", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateKesehatanDto.prototype, "tindakan", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateKesehatanDto.prototype, "obat", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateKesehatanDto.prototype, "tempat", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreateKesehatanDto.prototype, "tanggal", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(client_1.StatusKesehatan),
    __metadata("design:type", String)
], CreateKesehatanDto.prototype, "status", void 0);
class CreateKunjunganDto {
}
exports.CreateKunjunganDto = CreateKunjunganDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateKunjunganDto.prototype, "santriId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateKunjunganDto.prototype, "waliId", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreateKunjunganDto.prototype, "tanggal", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateKunjunganDto.prototype, "catatan", void 0);
class CreateTataTertibDto {
}
exports.CreateTataTertibDto = CreateTataTertibDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateTataTertibDto.prototype, "judul", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateTataTertibDto.prototype, "isi", void 0);
class QueryKesantrianDto {
}
exports.QueryKesantrianDto = QueryKesantrianDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], QueryKesantrianDto.prototype, "santriId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], QueryKesantrianDto.prototype, "kelasId", void 0);
//# sourceMappingURL=kesantrian.dto.js.map