-- Copyright (c) 2010 Aleksey Yeschenko <aleksey@yeschenko.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

if not arg[3] then
    print("usage: lua local_thr.lua <bind-to> <message-size> <message-count>")
    os.exit()
end

local bind_to = arg[1]
local message_size = tonumber(arg[2])
local message_count = tonumber(arg[3])

local zmq = require"zmq"
local z_poller = require"zmq.poller"
local z_NOBLOCK = zmq.NOBLOCK

local poller = z_poller(64)

local ctx = zmq.init(1)
local s = ctx:socket(zmq.SUB)
s:setopt(zmq.SUBSCRIBE, "");
s:bind(bind_to)

print(string.format("message size: %i [B]", message_size))
print(string.format("message count: %i", message_count))

local msg
msg = zmq.zmq_msg_t()

local cnt = 0

poller:add(s, zmq.POLLIN, function(sock)
	while s:recv_msg(msg, z_NOBLOCK) do
		--assert(msg:size() == message_size, "Invalid message size")
		cnt = cnt + 1
		if cnt == message_count then
			poller:stop()
		end
	end
end)

-- wait for first message
assert(s:recv_msg(msg))
cnt = 1

local timer = zmq.stopwatch_start()
poller:start()
local elapsed = timer:stop()

s:close()
ctx:term()

if elapsed == 0 then elapsed = 1 end

local throughput = message_count / (elapsed / 1000000)
local megabits = throughput * message_size * 8 / 1000000

print(string.format("mean throughput: %i [msg/s]", throughput))
print(string.format("mean throughput: %.3f [Mb/s]", megabits))

