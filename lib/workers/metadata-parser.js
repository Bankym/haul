const { parentPort, workerData } = require('worker_threads');

/**
 * Parse metadata from buffer in a worker thread
 * This handles the CPU-intensive synchronous buffer parsing
 */

const parser = {

    JPEG: (buff) => {
        const sof = [0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf, 0xde];
        let pos = 0;
        let width = null, height = null;

        while (buff[pos++] == 0xff) {
            let marker = buff[pos++];
            let size = buff.readUInt16BE(pos);

            if (marker == 0xda) break;

            if (sof.includes(marker)) {
                height = buff.readUInt16BE(pos + 3);
                width = buff.readUInt16BE(pos + 5);
                break;
            }

            pos += size;
        }

        return { width, height };
    },

    TIFF: (buff) => {
        const le = buff.toString('ascii', 0, 2) == 'II';
        let pos = 0;
        let width = null, height = null;
        
        const readUInt16 = () => { pos += 2; return buff[le ? 'readUInt16LE' : 'readUInt16BE'](pos - 2); }
        const readUInt32 = () => { pos += 4; return buff[le ? 'readUInt32LE' : 'readUInt32BE'](pos - 4); }

        let offset = readUInt32();
        
        while (pos < buff.length && offset > 0) {
            let entries = readUInt16(offset);
            let start = pos;

            for (let i = 0; i < entries; i++) {
                let tag = readUInt16();
                let type = readUInt16();
                let length = readUInt32();
                let data = (type == 3) ? readUInt16() : readUInt32();
                if (type == 3) pos += 2;

                if (tag == 256) {
                    width = data;
                } else if (tag == 257) {
                    height = data;
                }

                if (width > 0 && height > 0) {
                    return { width, height };
                }
            }

            offset = readUInt32();
            pos += offset;
        }

        return { width, height };
    },

    MOV: (buff, startPos = 0) => {
        let pos = startPos;
        let width = null, height = null, duration = null;

        while (pos < buff.length) {
            let size = buff.readUInt32BE(pos);
            let name = buff.toString('ascii', pos + 4, pos + 8);

            if (name == 'mvhd') {
                let scale = buff.readUInt32BE(pos + 20);
                let dur = buff.readUInt32BE(pos + 24);
                duration = ~~(dur / scale);
            }

            if (name == 'tkhd') {
                let m0 = buff.readUInt32BE(pos + 48);
                let m4 = buff.readUInt32BE(pos + 64);
                let w = buff.readUInt32BE(pos + 84);
                let h = buff.readUInt32BE(pos + 88);
                if (w > 0 && h > 0) {
                    width = w / m0;
                    height = h / m4;
                    return { width, height, duration };
                }
            }

            if (name == 'moov' || name == 'trak') {
                const result = parser.MOV(buff, pos + 8);
                if (result.width) return result;
            }

            pos += size;
        }

        return { width, height, duration };
    },

    OGG: (buff) => {
        let pos = 0;
        let vorbis = null;
        let width = null, height = null, duration = null;

        while (buff.toString('ascii', pos, pos + 4) == 'OggS') {
            let version = buff[pos + 4];
            let b = buff[pos + 5];
            let continuation = !!(b & 0x01);
            let bos = !!(b & 0x02);
            let eos = !!(b & 0x04);
            let position = Number(buff.readBigUInt64LE(pos + 6));
            let serial = buff.readUInt32LE(pos + 14);
            let pageNumber = buff.readUInt32LE(pos + 18);
            let checksum = buff.readUInt32LE(pos + 22);
            let pageSegments = buff[pos + 26];
            let lacing = buff.slice(pos + 27, pos + 27 + pageSegments);
            let pageSize = lacing.reduce((p, v) => p + v, 0);
            let start = pos + 27 + pageSegments;
            let pageHeader = buff.slice(start, start + 7);

            if (pageHeader.compare(Buffer.from([0x01, 'v', 'o', 'r', 'b', 'i', 's'])) == 0) {
                vorbis = { serial, sampleRate: buff.readUInt32LE(start + 12) };
            }

            if (pageHeader.compare(Buffer.from([0x80, 't', 'h', 'e', 'o', 'r', 'a'])) == 0) {
                let ver = buff.slice(start + 7, start + 10);
                width = buff.readUInt16BE(start + 10) << 4;
                height = buff.readUInt16BE(start + 12) << 4;

                if (ver >= 0x030200) {
                    let w = buff.slice(start + 14, start + 17);
                    let h = buff.slice(start + 17, start + 20);

                    if (w <= width && w > width - 16 && h <= height && h > height - 16) {
                        width = w;
                        height = h;
                    }
                }
            }

            if (eos && vorbis && serial == vorbis.serial) {
                duration = ~~(position / vorbis.sampleRate);
            }

            pos = start + pageSize;
        }

        return { width, height, duration };
    },

    MP3: (buff) => {
        const versions = [2.5, 0, 2, 1];
        const layers = [0, 3, 2, 1];
        const bitrates = [
            [ // version 2.5
                [0, 0, 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0], // reserved
                [0, 8,16,24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160], // layer 3
                [0, 8,16,24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160], // layer 2
                [0,32,48,56, 64, 80, 96,112,128,144,160,176,192,224,256]  // layer 1
            ],
            [ // reserved
                [0, 0, 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0], // reserved
                [0, 0, 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0], // reserved
                [0, 0, 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0], // reserved
                [0, 0, 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0]  // reserved
            ],
            [ // version 2
                [0, 0, 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0], // reserved
                [0, 8,16,24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160], // layer 3
                [0, 8,16,24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160], // layer 2
                [0,32,48,56, 64, 80, 96,112,128,144,160,176,192,224,256]  // layer 1
            ],
            [ // version 1
                [0, 0, 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0], // reserved
                [0,32,40,48, 56, 64, 80, 96,112,128,160,192,224,256,320], // layer 3
                [0,32,48,56, 64, 80, 96,112,128,160,192,224,256,320,384], // layer 2
                [0,32,64,96,128,160,192,224,256,288,320,352,384,416,448]  // layer 1
            ]
        ];
        const srates = [
            [11025, 12000,  8000, 0], // mpeg 2.5
            [    0,     0,     0, 0], // reserved
            [22050, 24000, 16000, 0], // mpeg 2
            [44100, 48000, 32000, 0]  // mpeg 1
        ];
        const tsamples = [
            [0,  576, 1152, 384], // mpeg 2.5
            [0,    0,    0,   0], // reserved
            [0,  576, 1152, 384], // mpeg 2
            [0, 1152, 1152, 384]  // mpeg 1
        ];
        const slotSizes = [0, 1, 1, 4];
        const modes = ['stereo', 'joint_stereo', 'dual_channel', 'mono'];

        let duration = 0;
        let count = 0;
        let skip = 0;
        let pos = 0;

        while (pos < buff.length) {
            let start = pos;

            if (buff.toString('ascii', pos, pos + 4) == 'TAG+') {
                skip += 227;
                pos += 227;
            } else if (buff.toString('ascii', pos, pos + 3) == 'TAG') {
                skip += 128;
                pos += 128;
            } else if (buff.toString('ascii', pos, pos + 3) == 'ID3') {
                let bytes = buff.readUInt32BE(pos + 6);
                let size = 10 + (bytes[0] << 21 | bytes[1] << 14 | bytes[2] << 7 | bytes[3]);
                skip += size;
                pos += size;
            } else {
                let hdr = buff.slice(pos, pos + 4);

                while (pos < buff.length && !(hdr[0] == 0xff && (hdr[1] & 0xe0) == 0xe0)) {
                    pos++;
                    hdr = buff.slice(pos, pos + 4);
                }

                let ver = (hdr[1] & 0x18) >> 3;
                let lyr = (hdr[1] & 0x06) >> 1;
                let pad = (hdr[2] & 0x02) >> 1;
                let brx = (hdr[2] & 0xf0) >> 4;
                let srx = (hdr[2] & 0x0c) >> 2;
                let mdx = (hdr[3] & 0xc0) >> 6;

                let version = versions[ver];
                let layer = layers[lyr];
                let bitrate = bitrates[ver][lyr][brx] * 1000;
                let samprate = srates[ver][srx];
                let samples = tsamples[ver][lyr];
                let slotSize = slotSizes[lyr];
                let mode = modes[mdx];
                let fsize = ~~(((samples / 8 * bitrate) / samprate) + (pad ? slotSize : 0));

                count++;

                if (count == 1) {
                    if (layer != 3) {
                        pos += 2;
                    } else {
                        if (mode != 'mono') {
                            if (version == 1) {
                                pos += 32;
                            } else {
                                pos += 17;
                            }
                        } else {
                            if (version == 1) {
                                pos += 17;
                            } else {
                                pos += 9;
                            }
                        }
                    }

                    if (buff.toString('ascii', pos, pos + 4) == 'Xing' && (buff.readUInt32BE(pos + 4) & 0x0001) == 0x0001) {
                        let totalFrames = buff.readUInt32BE(pos + 8);
                        duration = totalFrames * samples / samprate;
                        break;
                    }
                }

                if (fsize < 1) break;

                pos = start + fsize;

                duration += (samples / samprate);
            }
        }

        return { duration: ~~duration };
    }

};

// Worker thread execution
try {
    const { type, buffer } = workerData;
    const buff = Buffer.from(buffer);
    
    if (parser[type]) {
        const result = parser[type](buff);
        parentPort.postMessage(result);
    } else {
        parentPort.postMessage({});
    }
} catch (error) {
    throw error;
}
