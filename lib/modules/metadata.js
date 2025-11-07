const fs = require('fs-extra');
const { join } = require('path');
const { runWorker } = require('../core/worker');

const imageTypes = ['PNG', 'GIF', 'BMP', 'JPEG', 'TIFF'];
const videoTypes = ['AVI', 'MP4', 'MOV', 'MKV', 'WEBM', 'OGV'];
const soundTypes = ['OGG', 'WAV', 'MP3', 'FLAC'];

// File types that need worker thread due to complex parsing
const WORKER_TYPES = ['JPEG', 'TIFF', 'MP4', 'MOV', 'OGG', 'MP3'];

const read = async (path, offset, length) => {
    const fp = await fs.open(path);
    const buff = Buffer.alloc(length);
    
    await fs.read(fd, buff, 0, length, offset);
    await fs.close();

    return buff;
};


const parser = {

    PNG: async (path, result) => {
        const buff = await read(path, 18, 6);
        result.width = buff.readUInt16BE(0);
        result.height = buff.readUInt16BE(4);
    },

    GIF: async (path, result) => {
        const buff = await read(path, 6, 4);
        result.width = buff.readUInt16LE(0);
        result.height = buff.readUInt16LE(2);
    },

    BMP: async (path, result) => {
        const buff = await read(path, 18, 8);
        result.width = buff.readUInt32LE(0);
        result.height = buff.readUInt32LE(4);
    },

    JPEG: async (path, result) => {
        const buff = await read(path, 2, 64000);
        
        // Use worker thread for CPU-intensive synchronous parsing
        const workerFile = join(__dirname, '..', 'workers', 'metadata-parser.js');
        const parsed = await runWorker(workerFile, { type: 'JPEG', buffer: buff });
        result.width = parsed.width;
        result.height = parsed.height;
    },

    TIFF: async (path, result) => {
        const buff = await read(path, 0, 64000);
        
        // Use worker thread for CPU-intensive synchronous parsing
        const workerFile = join(__dirname, '..', 'workers', 'metadata-parser.js');
        const parsed = await runWorker(workerFile, { type: 'TIFF', buffer: buff });
        result.width = parsed.width;
        result.height = parsed.height;
    },

    AVI: async (path, result) => {
        const buff = await read(path, 0, 144);
        result.width = buff.readUInt32LE(64);
        result.height = buff.readUInt32LE(68);
        result.duration = ~~(buff.readUInt32LE(128) / buff.readUInt32LE(132) * buff.readUInt32LE(140));
    },

    MP4: async (path, result) => {
        return parser.MOV(path, result);
    },

    MOV: async (path, result, pos = 0) => {
        const buff = await read(path, 0, 64000);
        
        // Use worker thread for CPU-intensive synchronous parsing
        const workerFile = join(__dirname, '..', 'workers', 'metadata-parser.js');
        const parsed = await runWorker(workerFile, { type: 'MOV', buffer: buff });
        result.width = parsed.width;
        result.height = parsed.height;
        result.duration = parsed.duration;
    },

    WEBM: async (path, result) => {
        return parser.EBML(path, result);
    },

    MKV: async (path, result) => {
        return parser.EBML(path, result);
    },

    EBML: async (path, result) => {
        const containers = ['\x1a\x45\xdf\xa3', '\x18\x53\x80\x67', '\x15\x49\xa9\x66', '\x16\x54\xae\x6b', '\xae', '\xe0'];
        const buff = await read(path, 0, 64000);

        // TODO parse EBML
    },

    OGV: async (path, result) => {
        return parser.OGG(path, result);
    },

    OGG: async (path, result) => {
        const buff = await read(path, 0, 64000);
        
        // Use worker thread for CPU-intensive synchronous parsing
        const workerFile = join(__dirname, '..', 'workers', 'metadata-parser.js');
        const parsed = await runWorker(workerFile, { type: 'OGG', buffer: buff });
        result.width = parsed.width;
        result.height = parsed.height;
        result.duration = parsed.duration;
    },

    WAV: async (path, result) => {
        const buff = await read(path, 0, 32);
        let size = buff.readUInt32LE(4);
        let rate = buff.readUInt32LE(28);
        result.duration = ~~(size / rate);
    },

    MP3: async (path, result) => {
        const buff = await read(path, 0, 64000);
        
        // Use worker thread for CPU-intensive synchronous parsing
        const workerFile = join(__dirname, '..', 'workers', 'metadata-parser.js');
        const parsed = await runWorker(workerFile, { type: 'MP3', buffer: buff });
        result.duration = parsed.duration;
    },

    FLAC: async (path, result) => {
        const buff = await read(path, 18, 8);
        let rate = (buff[0] << 12) | (buff[1] << 4) | ((buff[2] & 0xf0) >> 4);
        let size = ((buff[3] & 0x0f) << 32) | (buff[4] << 24) | (buff[5] << 16) | (buff[6] << 8) | buff[7];
        result.duration = ~~(size / rate);
    },

};

async function detect(path) {
    const buff = await read(path, 0, 12);

    if (buff.slice(0, 8).compare(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
        return 'PNG';
    }

    if (buff.toString('ascii', 0, 3) == 'GIF') {
        return 'GIF';
    }

    if (buff.toString('ascii', 0, 2) == 'BM') {
        return 'BMP';
    }

    if (buff.slice(0, 2).compare(Buffer.from([0xff, 0xd8]))) {
        return 'JPEG';
    }

    if (buff.toString('ascii', 0, 2) == 'II' && buff.readUInt16LE(2) == 42) {
        return 'TIFF';
    }

    if (buff.toString('ascii', 0, 2) == 'MM' && buff.readUInt16BE(2) == 42) {
        return 'TIFF';
    }

    if (buff.toString('ascii', 0, 4) == 'RIFF' && buff.toString('ascii', 8, 4) == 'AVI ') {
        return 'AVI';
    }

    if (buff.toString('ascii', 4, 4) == 'ftyp') {
        return 'MP4';
    }

    if (buff.toString('ascii', 4, 4) == 'moov') {
        return 'MOV';
    }

    if (buff.slice(0, 4).compare(Buffer.from([0x1a, 0x45, 0xdf, 0xa3]))) {
        // TODO detect MKV

        return 'EBML';
    }

    if (buff.toString('ascii', 0, 4) == 'OggS') {
        // TODO detect OGV
        
        return 'OGG'
    }

    if (buff.toString('ascii', 0, 4) == 'RIFF', buff.toString('ascii', 8, 4) == 'WAVE') {
        return 'WAV';
    }

    if (buff.toString('ascii', 0, 3) == 'ID3' || (buf[0] == 0xff && (buff[1] & 0xe0))) {
        return 'MP3';
    }

    if (buff.toString('ascii', 0, 4) == 'fLaC') {
        return 'FLAC';
    }

    return null
}

module.exports = {

    detect: async function(options) {
        let path = this.parseRequired(options.path, 'string', 'metadata.detect: path is required.');

        return detect(path);
    },

    isImage: async function(options) {
        let path = this.parseRequired(options.path, 'string', 'metadata.isImage: path is required.');
        let type = await detect(path);
        let cond = imageTypes.includes(type);
        
        if (cond) {
            if (options.then) {
                await this.exec(options.then, true);
            }
        } else if (options.else) {
            await this.exec(options.else, true);
        }

        return cond;
    },

    isVideo: async function(options) {
        let path = this.parseRequired(options.path, 'string', 'metadata.isVideo: path is required.');
        let type = await detect(path);
        let cond = videoTypes.includes(type);
        
        if (cond) {
            if (options.then) {
                await this.exec(options.then, true);
            }
        } else if (options.else) {
            await this.exec(options.else, true);
        }

        return cond;
    },

    isSound: async function(options) {
        let path = this.parseRequired(options.path, 'string', 'metadata.isSound: path is required.');
        let type = await detect(path);
        let cond = soundTypes.includes(type);
        
        if (cond) {
            if (options.then) {
                await this.exec(options.then, true);
            }
        } else if (options.else) {
            await this.exec(options.else, true);
        }

        return cond;
    },

    fileinfo: async function(options) {
        let path = this.parseRequired(options.path, 'string', 'metadata.fileinfo: path is required.');
        let type = await detect(path);
        let result = { type, width: null, height: null, duration: null };

        if (parser[type]) {
            await parser[type](path, result);
        }

        return result;
    },

};