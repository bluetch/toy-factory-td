## SkillData — defines a single Roguelike skill.
## All skill definitions are constructed in SkillManager._build_pool();
## no .tres files needed.
class_name SkillData
extends RefCounted

var skill_id:     String = ""
var skill_name:   String = ""
var description:  String = ""
var icon:         String = "⚡"
var rarity:       int    = 0      ## 0 = common  1 = rare  2 = epic
var max_stacks:   int    = 3      ## max times this skill can be selected (0 = unlimited)
var tower_filter: String = ""     ## "" = global; "ArrowTower" etc. = tower-specific
var effect_type:  String = ""     ## see SkillManager for recognised effect types
var effect_value: float  = 0.0
