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

    pub fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }
};

fn _calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        // const n_output: usize = 4;
        // return n_output;

        return 4;
    }

    const n_output: usize = try std.math.divCeil(usize, input.len, 3);

    return n_output * 4;
}

fn _calc_decode_length(input: []const u8) !usize {
    if (input.len < 4) {
        // const n_output: usize = 3;
        // return n_output;

        return 3;
    }

    const n_output: usize = try std.math.divFloor(usize, input.len, 4);

    return n_output * 3;
}

pub fn main() !void {

}
