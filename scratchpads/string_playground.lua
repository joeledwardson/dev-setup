local my_string = "hello, there = pls"

local a, b, c, d = my_string:find(",([^=]+)")
print(a, b, c, d)
