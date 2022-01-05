local class = require("class")
-- non-typechecked class
local classRef = class "user" {
    static = {
        numberOfUsers = 0
    },
    numberOfFriends = 0,
    creationTime = 0,
}

local testUser1 = classRef.new()

assert(testUser1.numberOfFriends == 0)
assert(testUser1.creationTime == 0)

-- TODO: default constructor
-- TODO: ensure unique type names in a module(overload require)
-- NOTE: this is expected to fail on an assert:
local class2Ref = class "user2" "strict"{
    static = {
        numberOfUsers = "number"
    },
    numberOfFriends = "number",
    creationTime = "number",
    default = function(self,...)
        local params = {...}
        self.numberOfFriends = params[1]
        self.numberOfUsers = params[2]
    end
}
local testUser2 = class2Ref.new(1, 2)


assert(testUser1.numberOfFriends == 1)
assert(testUser1.creationTime == 2)

-- TODO: inferred types class