-- mpv issue 5222
-- Automatically set loop-file=inf for duration <= given length. Default is 5s
-- Use autoloop_duration=n in script-opts/autoloop.conf to set your preferred length
-- Alternatively use script-opts=autoloop-autoloop_duration=n in mpv.conf (takes priority)
-- Also disables the save-position-on-quit for this file, if it qualifies for looping.

require("mp.options")
function set_loop()
	local rotated = mp.get_property("video-rotate")
	print("joel says hello there!")
	print("aaand, the video is rotated as ", rotated)
	print("the type of rotated var is ", type(rotated))
end

mp.register_event("file-loaded", set_loop)
