"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.KesantrianModule = void 0;
const common_1 = require("@nestjs/common");
const kesantrian_service_1 = require("./kesantrian.service");
const kesantrian_controller_1 = require("./kesantrian.controller");
let KesantrianModule = class KesantrianModule {
};
exports.KesantrianModule = KesantrianModule;
exports.KesantrianModule = KesantrianModule = __decorate([
    (0, common_1.Module)({
        controllers: [kesantrian_controller_1.KesantrianController],
        providers: [kesantrian_service_1.KesantrianService],
        exports: [kesantrian_service_1.KesantrianService],
    })
], KesantrianModule);
//# sourceMappingURL=kesantrian.module.js.map