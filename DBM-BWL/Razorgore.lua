local mod	= DBM:NewMod("Razorgore", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(12435, 99999)--Bogus detection to prevent invalid kill detection if razorgore happens to die in phase 1

--mod:DisableEEKillDetection()--So disable only EE
mod:SetModelID(12435)

mod:RegisterCombat("yell", L.YellPull)
mod:SetWipeTime(180)--guesswork


mod:RegisterEventsInCombat(
	"SPELL_CAST_START 22425",
	"SPELL_CAST_SUCCESS 23040 19873 23023",
	"SPELL_AURA_APPLIED 23023",
	"CHAT_MSG_MONSTER_EMOTE",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED"
)


--ability.id = 22425 and type = "begincast" or (ability.id = 23040 or ability.id = 19873) and type = "cast"
local warnPhase2			= mod:NewPhaseAnnounce(2)
local warnFireballVolley	= mod:NewCastAnnounce(22425, 3)
local warnConflagration		= mod:NewTargetNoFilterAnnounce(23023, 2)
local warnEggsLeft			= mod:NewCountAnnounce(19873, 1)

local specWarnFireballVolley= mod:NewSpecialWarningMoveTo(22425, false, nil, nil, 2, 2)

local timerAddsSpawn		= mod:NewTimer(45, "TimerAddsSpawn", 19879, nil, nil, 1)--Only for start of adds, not adds after the adds.
local timerConflag			= mod:NewCDTimer(30, 23023, nil, false)


mod.vb.eggsLeft = 30

function mod:OnCombatStart()
	self:SetStage(1)
	timerAddsSpawn:Start()
	self.vb.eggsLeft = 30
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 22425 then
		if self.Options.SpecWarn22425moveto then
			specWarnFireballVolley:Show(DBM_COMMON_L.BREAK_LOS)
			specWarnFireballVolley:Play("findshelter")
		else
			warnFireballVolley:Show()
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 23040 and self.vb.phase < 2 then
		warnPhase2:Show()
		self:SetStage(2)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 23023 and args:IsDestTypePlayer() then
		warnConflagration:CombinedShow(0.3, args.destName)
	end
end

--For some reason this no longer works
function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L.YellEgg1 or msg == L.YellEgg2 or msg == L.YellEgg3) and self.vb.phase < 2 and self.vb.eggsLeft > 1 then
		self.vb.eggsLeft = self.vb.eggsLeft - 1
		warnEggsLeft:Show(string.format("%d/%d",30-self.vb.eggsLeft,30))
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if (msg == L.Phase2Emote or msg:find(L.Phase2Emote)) and self.vb.phase < 2 then
		self:SendSync("Phase2")
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 12435 then--Only trigger kill for unit_died if he dies in phase 2 with everyone alive, otherwise it's an auto wipe.
		if DBM:NumRealAlivePlayers() > 0 and self.vb.phase == 2 then
			DBM:EndCombat(self)
		else
			DBM:EndCombat(self, true)--Pass wipe arg end combat
		end
	end
end

function mod:OnSync(msg)
	if msg == "Phase2" and self.vb.phase < 2 then
		warnPhase2:Show()
		self:SetStage(2)
		timerConflag:Start(12)
	end
end
