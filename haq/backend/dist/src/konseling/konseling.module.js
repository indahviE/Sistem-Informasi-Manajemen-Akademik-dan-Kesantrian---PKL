"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.KonselingModule = void 0;
const common_1 = require("@nestjs/common");
const konseling_controller_1 = require("./konseling.controller");
const konseling_service_1 = require("./konseling.service");
let KonselingModule = class KonselingModule {
};
exports.KonselingModule = KonselingModule;
exports.KonselingModule = KonselingModule = __decorate([
    (0, common_1.Module)({
        controllers: [konseling_controller_1.KonselingController],
        providers: [konseling_service_1.KonselingService],
    })
], KonselingModule);
//# sourceMappingURL=konseling.module.js.map