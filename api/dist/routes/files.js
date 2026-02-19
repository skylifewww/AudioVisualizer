"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const router = (0, express_1.Router)();
// Serve .visual and .meta.json files
router.get('/:filename', (req, res) => {
    const filename = req.params.filename;
    const filePath = path_1.default.join(__dirname, '..', '..', 'visuals', filename);
    if (!fs_1.default.existsSync(filePath)) {
        return res.status(404).json({ error: 'File not found' });
    }
    res.sendFile(filePath);
});
exports.default = router;
