const std = @import("std");

const Base64 = struct {
    _table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const num_and_sym = "0123456789+/";

        return Base64 {
            ._table = upper ++ lower ++ num_and_sym,
        };
    }

    pub fn encode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const n_out = try _calc_encode_length(input);
        var out = try allocator.alloc(u8, n_out);
        var buf = [3]u8{0, 0, 0};
        var count: u8 = 0;
        var iout: u64 = 0;

        for (input, 0..) |_, i| {
            buf[count] = input[i];
            count += 1;

            // let buf[0] = ABCDEFGH
            //     buf[1] = IJKLMNOP
            //     buf[2] = QRSTUVWX
            if (count == 3) {

                // ABCDEFGH >> 2 => 00ABCDEF
                // <- 00ABCDEF
                out[iout] = self._char_at(buf[0] >> 2);

                // ABCDEFGH & 0x03  => 000000GH (since 0x00 = 0b11)
                // 000000GH << 4 => 00GH0000
                // IJKLMNOP >> 4 => 0000IJKL
                // 0000IJKL + 00GH0000 => 00GHIJKL
                // <- 00GHIJKL
                out[iout + 1] = self._char_at(((buf[0] & 0x03) << 4) + (buf[1] >> 4));

                // IJKLMNOP & 0x0f => 0000MNOP (since 0x0f = 0b1111)
                // 0000MNOP << 2 => 00MNOP00
                // QRSTUVWX >> 6 => 000000QR
                // 00MNOP00 + 000000QR => 00MNOPQR
                // <- 00MNOPQR
                out[iout + 2] = self._char_at(((buf[1] & 0x0f) << 2) + (buf[2] >> 6));

                // QRSTUVWX & 0x3f => 00STUVWX (since 0x3f = 0b111111)
                // <- 00STUVWX
                out[iout + 3] = self._char_at(buf[2] & 0x3f);

                iout += 4;
                count = 0;
            }
        }

        if (count == 1) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at((buf[0] & 0x03) << 4);
            out[iout + 2] = '=';
            out[iout + 3] = '=';
        }

        if (count == 2) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
            out[iout + 2] = self._char_at((buf[1] & 0x0f) << 2);
            out[iout + 3] = '=';
            iout += 4;
        }

        return out;
    }

    pub fn decode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const n_output = try _calc_decode_length(input);
        var out = try allocator.alloc(u8, n_output);
        var count: u8 = 0;
        var iout: u64 = 0;
        var buf = [4]u8{0, 0, 0, 0};

        for (0..input.len) |i| {
            buf[count] = self._char_index(input[i]);
            count += 1;

            if (count == 4) {
                out[iout] = (buf[0] << 2) + (buf[1] >> 4);

                if (buf[2] != 64) {
                    out[iout + 1] = (buf[1] << 4) + (buf[2] >> 2);
                }

                if (buf[3] != 64) {
                    out[iout + 2] = (buf[2] << 6) + buf[3];
                }

                iout += 3;
                count = 0;
            }
        }

        return out;
    }

    fn _calc_encode_length(input: []const u8) !usize {
        if (input.len < 3) {
            return 4;
        }

        const n_output: usize = try std.math.divCeil(usize, input.len, 3);

        return n_output * 4;
    }

    fn _calc_decode_length(input: []const u8) !usize {
        if (input.len < 4) {
            return 3;
        }

        const n_output: usize = try std.math.divFloor(usize, input.len, 4);

        return n_output * 3;
    }

    fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }

    fn _char_index(self: Base64, char: u8) u8 {
        if (char == '=') return 64;

        var index: u8 = 0;

        for (0..63) |i| {
            if (self._char_at(i) == char)
                break;

            index += 1;
        }

        return index;
    }

};

pub fn main() !void {

}

test "first test" {
    var mem_buf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&mem_buf);
    const allocator = fba.allocator();

    const text = "Testing some more stuff";
    const etext = "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=";
    const base64 = Base64.init();
    const encoded_text = try base64.encode(allocator, text);
    const decoded_text = try base64.decode(allocator, etext);

    const stdout = std.io.getStdOut().writer();

    try stdout.print(
        "Encoded text: {s}\n", .{encoded_text}
    );

    try stdout.print(
        "Decoded text: {s}\n", .{decoded_text}
    );
}
