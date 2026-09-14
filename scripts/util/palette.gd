class_name Palette
extends RefCounted
## Shared color palette so every hand-drawn object in the game reads as one
## cohesive art style instead of independently-chosen colors.

# Ground
const GRASS := Color("6ba644")
const GRASS_DARK := Color("5c9339")
const GRASS_PATCH_A := Color("7bb654")
const GRASS_PATCH_B := Color("8fc25e")

# Water
const WATER_SHALLOW := Color("6ec6d9")
const WATER_DEEP := Color("3a8fb0")
const WATER_POND := Color("3a7fc9")
const WATER_POND_DEEP := Color("2a5fa0")

# Wood / bark / stone
const BARK := Color("7a5238")
const BARK_DARK := Color("5c3c28")
const WOOD_LIGHT := Color("c98b4f")
const WOOD_MID := Color("b06f3a")
const WOOD_DARK := Color("8a5228")
const STONE_LIGHT := Color("aab0b8")
const STONE_MID := Color("8a919c")
const STONE_DARK := Color("666d76")

# Foliage
const LEAF_LIGHT := Color("6cbf5a")
const LEAF_MID := Color("4fa348")
const LEAF_DARK := Color("368239")
const BUSH_LIGHT := Color("5fae4f")
const BUSH_DARK := Color("3f8a3f")
const BERRY := Color("bf4050")
const ENERGY_LOW := Color("ff8c4d")

# Beaver
const FUR_LIGHT := Color("a9764a")
const FUR_MID := Color("8a5c38")
const FUR_DARK := Color("6b4527")
const FUR_BELLY := Color("d9ac6f")
const TAIL_COLOR := Color("4a3020")
const TAIL_SCALE := Color("5c3d29")

# Common
const OUTLINE := Color(0.15, 0.1, 0.08, 0.55)
const SHADOW := Color(0.05, 0.08, 0.05, 0.28)
const HIGHLIGHT_RING := Color("fff0a0")
const LOCK_BODY := Color(0.35, 0.35, 0.38, 0.9)

# Lodge
const ROOF := Color("a4402f")
const ROOF_DARK := Color("833325")
const DOOR := Color("3c2818")
const WINDOW_GLOW := Color("ffdf8c")

# Critters
const FROG_BODY := Color("5fa347")
const FROG_BELLY := Color("cfe6a8")
const DUCK_BODY := Color("f6f1e4")
const DUCK_BILL := Color("e8a838")
const FISH_BODY := Color("5b93c9")
const FISH_BELLY := Color("bcd8ee")
const BUTTERFLY_WING := Color("d98bb0")
const RABBIT_FUR := Color("ddd7cd")

# Garden decorations
const PETAL_PINK := Color("e6708f")
const PETAL_YELLOW := Color("f2cc4d")
const PETAL_PURPLE := Color("9a72c9")
const PETAL_ORANGE := Color("ec8b3f")
const PETAL_CENTER := Color("fce77d")

# Storms & scavengers
const LEAK_WATER := Color("74b8d9")
const CRACK := Color("26211d")
const RACCOON_FUR := Color("6b6664")
const RACCOON_MASK := Color("262220")
const RACCOON_TAIL_LIGHT := Color("d9d6d0")
