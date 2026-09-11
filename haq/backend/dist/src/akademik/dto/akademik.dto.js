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
exports.QueryAbsensiDto = exports.CreateTahfidzDto = exports.CreateNilaiDto = exports.BulkAbsensiDto = exports.CreateAbsensiDto = void 0;
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
class CreateAbsensiDto {
}
exports.CreateAbsensiDto = CreateAbsensiDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateAbsensiDto.prototype, "santriId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateAbsensiDto.prototype, "kelasId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateAbsensiDto.prototype, "mapelId", void 0);
__decorate([
    (0, class_validator_1.IsDateString)({}, { message: 'Tanggal tidak valid' }),
    __metadata("design:type", String)
], CreateAbsensiDto.prototype, "tanggal", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.AbsensiStatus, { message: 'Status absensi tidak valid' }),
    __metadata("design:type", String)
], CreateAbsensiDto.prototype, "status", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateAbsensiDto.prototype, "catatan", void 0);
class BulkAbsensiDto {
}
exports.BulkAbsensiDto = BulkAbsensiDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], BulkAbsensiDto.prototype, "kelasId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], BulkAbsensiDto.prototype, "mapelId", void 0);
__decorate([
    (0, class_validator_1.IsDateString)({}, { message: 'Tanggal tidak valid' }),
    __metadata("design:type", String)
], BulkAbsensiDto.prototype, "tanggal", void 0);
__decorate([
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], BulkAbsensiDto.prototype, "items", void 0);
class CreateNilaiDto {
}
exports.CreateNilaiDto = CreateNilaiDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateNilaiDto.prototype, "santriId", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateNilaiDto.prototype, "mapelId", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.JenisNilai, { message: 'Jenis nilai tidak valid' }),
    __metadata("design:type", String)
], CreateNilaiDto.prototype, "jenis", void 0);
__decorate([
    (0, class_validator_1.IsNumber)({}, { message: 'Nilai harus angka' }),
    (0, class_validator_1.Min)(0),
    (0, class_validator_1.Max)(100),
    __metadata("design:type", Number)
], CreateNilaiDto.prototype, "nilai", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateNilaiDto.prototype, "keterangan", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreateNilaiDto.prototype, "tanggal", void 0);
class CreateTahfidzDto {
}
exports.CreateTahfidzDto = CreateTahfidzDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateTahfidzDto.prototype, "santriId", void 0);
__decorate([
    (0, class_validator_1.IsInt)({ message: 'Juz harus angka' }),
    __metadata("design:type", Number)
], CreateTahfidzDto.prototype, "juz", void 0);
__decorate([
    (0, class_validator_1.IsInt)({ message: 'Halaman harus angka' }),
    __metadata("design:type", Number)
], CreateTahfidzDto.prototype, "halaman", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateTahfidzDto.prototype, "catatanUstadz", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreateTahfidzDto.prototype, "tanggalSetor", void 0);
class QueryAbsensiDto {
}
exports.QueryAbsensiDto = QueryAbsensiDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], QueryAbsensiDto.prototype, "santriId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], QueryAbsensiDto.prototype, "kelasId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], QueryAbsensiDto.prototype, "startDate", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], QueryAbsensiDto.prototype, "endDate", void 0);
//# sourceMappingURL=akademik.dto.js.map