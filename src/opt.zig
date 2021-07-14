const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const ArgTypeTag = enum {
    String,
    None,
};

pub const ArgType = union(ArgTypeTag) {
    String: ?[]u8,
    None: void,
};

pub fn Flag(comptime T: type) type {
    return struct {
        // Unique "ID" for flag (use enum)
        name: T,
        kind: ArgTypeTag = ArgTypeTag.None,

        // ignored if 'kind' is None
        mandatory: bool = false,

        // Should be unique within the parsing context
        short: ?u8 = null,
        long: ?[]const u8 = null,
    };
}

pub fn FlagValue(comptime T: type) type {
    return struct {
        name: T,
        value: ArgType,
    };
}

pub fn FlagIterator(comptime T: type) type {
    return struct {
        flags: []Flag(T),
        argv: [][]u8,
        count: u16 = 1,
        argcount: u16 = 1,
        pos: u16 = 0,
        stop: bool = false,
        argstop: bool = false,

        pub fn init(fl: []Flag(T), arg: [][]u8) FlagIterator(T) {
            return FlagIterator(T){
                .flags = fl,
                .argv = arg,
            };
        }

        pub fn next_flag(self: *FlagIterator(T)) !?FlagValue(T) {
            while (true) {
                if (self.stop or self.count >= self.argv.len) {
                    return null;
                }
                const curr = self.argv[self.count];
                if (self.pos == 0 and curr.len >= 2 and std.mem.eql(u8, curr[0..2], "--")) {
                    // Stop parsing after bare --
                    if (curr.len == 2) {
                        self.stop = true;
                        return null;
                    }
                    return try self.next_long();
                }
                // If - is followed by a character, short option
                if (curr.len >= 2 and curr[0] == '-') {
                    return try self.next_short();
                }
                // If neither - or --, then this is an argument, not an option,
                // and we ignore it
                self.count += 1;
                self.pos = 0;
            }
        }

        pub fn next_arg(self: *FlagIterator(T)) ?[]u8 {
            while (true) {
                if (self.argcount >= self.argv.len) {
                    return null;
                }
                const curr = self.argv[self.argcount];
                // If previously encountered bare --, then everything after is arg
                if (self.argstop) {
                    self.argcount += 1;
                    return curr;
                }
                // If no - or --, (or bare -) we've hit an arg, return it
                if (curr[0] != '-' or curr.len == 1) {
                    self.argcount += 1;
                    return curr;
                }

                // If bare --, ignore but set argstop to true
                if (std.mem.eql(u8, curr, "--")) {
                    self.argstop = true;
                    self.argcount += 1;
                    continue;
                }
                // If - or --, look ahead and see if next string is arg of flag
                if (self.check_arg()) {
                    self.argcount += 1;
                    if (self.argcount < self.argv.len) {
                        self.argcount += 1;
                        continue;
                    }
                    return null;
                }
                self.argcount += 1;
            }
        }

        fn next_long(self: *FlagIterator(T)) !?FlagValue(T) {
            const curr = self.argv[self.count];
            var eqindex = curr.len;
            for (curr) |ch, i| {
                if (ch == '=') {
                    eqindex = i;
                    break;
                }
            }
            const opt_flag = self.flag_from_long(curr[2..eqindex]);
            if (opt_flag) |flag| {
                if (flag.kind == ArgType.None) {
                    if (eqindex != curr.len) {
                        warn("{s}: option '{s}' doesn't allow an argument\n", .{ self.argv[0], curr[0..eqindex] });
                        warn("Try '{s} --help' for more information.\n", .{self.argv[0]});
                        return error.InvalidFlagArgument;
                    }
                    self.count += 1;
                    return FlagValue(T){ .name = flag.name, .value = ArgType.None };
                }
                // If can take argument and has =, use that
                if (eqindex != curr.len) {
                    self.count += 1;
                    return FlagValue(T){ .name = flag.name, .value = ArgType{ .String = curr[eqindex + 1 ..] } };
                }
                // If optional, return null string
                if (!flag.mandatory) {
                    self.count += 1;
                    return FlagValue(T){ .name = flag.name, .value = ArgType{ .String = null } };
                }
                // If mandatory, return next string
                if (self.count == self.argv.len - 1) {
                    warn("{s}: option '{s}' requires an argument.\n", .{ self.argv[0], curr[0..] });
                    warn("Try '{s} --help' for more information.\n", .{self.argv[0]});
                    return error.MissingFlagArgument;
                }
                self.count += 2;
                return FlagValue(T){ .name = flag.name, .value = ArgType{ .String = self.argv[self.count - 1] } };
            } else {
                // Error, invalid flag
                warn("{s}: unrecognized option '{s}'\n", .{ self.argv[0], curr[0..eqindex] });
                warn("Try '{s} --help' for more information.\n", .{self.argv[0]});
                return error.InvalidFlag;
            }
        }

        fn next_short(self: *FlagIterator(T)) !?FlagValue(T) {
            if (self.pos == 0) self.pos = 1;
            const curr = self.argv[self.count];
            const opt_flag = self.flag_from_short(curr[self.pos]);
            if (opt_flag) |flag| {
                if (flag.kind == ArgType.None) {
                    // No value and last char means move to next string afterwards
                    if (self.pos == curr.len - 1) {
                        self.pos = 0;
                        self.count += 1;
                    }
                    // No value and not last char means move to next char
                    else {
                        self.pos += 1;
                    }
                    return FlagValue(T){ .name = flag.name, .value = ArgType.None };
                }
                const oldpos = self.pos;
                self.pos = 0;
                self.count += 1;
                // If last character of word, mandatory/optional matters
                if (oldpos == curr.len - 1) {
                    if (flag.mandatory) {
                        if (self.count < self.argv.len) {
                            return FlagValue(T){
                                .name = flag.name,
                                .value = ArgType{ .String = self.argv[self.count] },
                            };
                        } else {
                            // Error, missing argument
                            warn("{s}: option requires an argument -- '{s}'\n", .{ self.argv[0], curr[oldpos .. oldpos + 1] });
                            warn("Try '{s} --help' for more information.\n", .{self.argv[0]});
                            return error.MissingFlagArgument;
                        }
                    }
                    // Flag with optional argument, last char of word
                    return FlagValue(T){
                        .name = flag.name,
                        .value = ArgType{ .String = null },
                    };
                }
                // If not last character of word, the rest of the word is value
                return FlagValue(T){
                    .name = flag.name,
                    .value = ArgType{ .String = curr[oldpos + 1 ..] },
                };
            } else {
                // Error, invalid flag
                warn("{s}: invalid option -- '{s}'\n", .{ self.argv[0], curr[self.pos .. self.pos + 1] });
                warn("Try '{s} --help' for more information.\n", .{self.argv[0]});
                return error.InvalidFlag;
            }
        }

        // Check whether the string after the current string in the arg iterator
        // is a bare arg (false) or an arg of a flag (true).
        // We assume the current string starts with '-'
        // (or possibly '--'  but not a bare '--')
        // Also return false if there is no next string.
        fn check_arg(self: *FlagIterator(T)) bool {
            if (self.argcount + 1 >= self.argv.len) {
                return true;
            }
            const curr = self.argv[self.argcount];
            // Handle --
            if (curr[1] == '-') {
                var eqindex = curr.len;
                for (curr) |ch, i| {
                    if (ch == '=') {
                        eqindex = i;
                        break;
                    }
                }
                const opt_flag = self.flag_from_long(curr[2..eqindex]);
                if (opt_flag) |flag| {
                    // Mandatory flag value means that = in the current string
                    // implies that the next string is NOT its argument
                    if (flag.mandatory) {
                        return eqindex == curr.len;
                    }
                }
                return false;
            }
            // Handle -
            for (curr) |ch, i| {
                // 0 index is always -
                if (i == 0) continue;
                const opt_flag = self.flag_from_short(ch);
                if (opt_flag) |flag| {
                    if (flag.kind == ArgType.None) continue;
                    // If last string of the word, depends on whether mandatory
                    if (i == curr.len - 1) {
                        return flag.mandatory;
                    }
                    // If can have an argument and not at end of word,
                    // next arg is bare
                    return false;
                }
            }
            // Unreachable
            return false;
        }

        fn flag_from_short(self: *FlagIterator(T), short: u8) ?Flag(T) {
            for (self.flags) |flag| {
                if (flag.short) |curr_short| {
                    if (short == curr_short) {
                        return flag;
                    }
                }
            }
            return null;
        }

        fn flag_from_long(self: *FlagIterator(T), long: []u8) ?Flag(T) {
            for (self.flags) |flag| {
                if (flag.long) |curr_long| {
                    if (std.mem.eql(u8, curr_long, long)) {
                        return flag;
                    }
                }
            }
            return null;
        }
    };
}
