"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TenantId = exports.CurrentUser = void 0;
const common_1 = require("@nestjs/common");
exports.CurrentUser = (0, common_1.createParamDecorator)((field, ctx) => {
    const req = ctx.switchToHttp().getRequest();
    const user = req.user;
    if (field) {
        return user?.[field];
    }
    return user;
});
exports.TenantId = (0, common_1.createParamDecorator)((_, ctx) => {
    const req = ctx.switchToHttp().getRequest();
    return req.user?.tenantId;
});
//# sourceMappingURL=current-user.decorator.js.map