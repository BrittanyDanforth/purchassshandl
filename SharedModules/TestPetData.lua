-- Test Pet Data for development
local TestPetData = {}

function TestPetData:GetTestPets()
    return {
        ["test_pet_1"] = {
            uniqueId = "test_pet_1",
            petId = "hello_kitty_basic",
            level = 1,
            experience = 0,
            equipped = false,
            locked = false,
            nickname = nil,
            variant = "NORMAL",
            obtained = os.time(),
            source = "test"
        },
        ["test_pet_2"] = {
            uniqueId = "test_pet_2",
            petId = "my_melody_basic",
            level = 5,
            experience = 250,
            equipped = true,
            locked = false,
            nickname = "Melody",
            variant = "SHINY",
            obtained = os.time() - 86400,
            source = "test"
        },
        ["test_pet_3"] = {
            uniqueId = "test_pet_3",
            petId = "kuromi_basic",
            level = 10,
            experience = 500,
            equipped = true,
            locked = true,
            nickname = nil,
            variant = "GOLDEN",
            obtained = os.time() - 172800,
            source = "test"
        },
        ["test_pet_4"] = {
            uniqueId = "test_pet_4",
            petId = "cinnamoroll_basic",
            level = 3,
            experience = 100,
            equipped = true,
            locked = false,
            nickname = nil,
            variant = "NORMAL",
            obtained = os.time() - 3600,
            source = "test"
        }
    }
end

return TestPetData