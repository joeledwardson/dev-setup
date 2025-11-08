-- Test file for type checking with custom classes

---@class Person
---@field name string The person's name
---@field age number The person's age
---@field email string The person's email

-- Correct usage - should have no warnings
---@type Person
local person1 = {
  name = 'John',
  age = 30,
  email = 'john@example.com',
  ssssssssss = 1,
}

-- Missing required field - should warn about missing 'email'
---@type Person
local person2 = {
  name = 'Jane',
  age = 25,
  -- missing email field
}

-- Extra undefined field - should warn about 'phone' not being defined
---@type Person
local person3 = {
  name = 'Bob',
  age = 35,
  email = 'bob@example.com',
  phone = '123-456-7890', -- undefined field!
  ssssssssss = 1,
}

print(person3.ssssssssss)

-- Wrong type for field - should warn about type mismatch
---@type Person
local person4 = {
  name = 'Alice',
  age = 'thirty', -- should be number, not string!
  email = 'alice@example.com',
}

-- Test with a function using the class
---@param p Person
---@return string
local function getPersonInfo(p)
  return p.name .. ' is ' .. p.age .. ' years old'
end

-- Call with correct type
getPersonInfo(person1)

-- Call with wrong type - should warn
getPersonInfo { random = 'data' }

-- Test undefined field access
print(person1.phone) -- should warn: undefined field 'phone'

-- Test with nested class
---@class Address
---@field street string
---@field city string
---@field country string

---@class Employee
---@field person Person
---@field address Address
---@field salary number

---@type Employee
local employee = {
  person = person1,
  address = {
    street = '123 Main St',
    city = 'New York',
    country = 'USA',
  },
  salary = 50000,
  department = 'Engineering', -- undefined field!
}

print 'Test file loaded - check for warnings above'
