"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const analyze_1 = __importDefault(require("./routes/analyze"));
const files_1 = __importDefault(require("./routes/files"));
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use('/api', analyze_1.default);
app.use('/files', files_1.default);
app.listen(PORT, () => {
    console.log(`API server running on http://localhost:${PORT}`);
});
