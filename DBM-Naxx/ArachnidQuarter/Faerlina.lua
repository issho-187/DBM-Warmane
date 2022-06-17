local mod	= DBM:NewMod("Faerlina", "DBM-Naxx", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(15953)
--mod:RegisterCombat("combat_yell", L.Pull)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 28798 54100 28732 54097 28794 54099",
	"SPELL_CAST_SUCCESS 28796 54098",
	"UNIT_DIED"
)

local warnEmbraceActive		= mod:NewSpellAnnounce(28732, 1)
local warnEmbraceExpire		= mod:NewAnnounce("WarningEmbraceExpire", 2, 28732)
local warnEmbraceExpired	= mod:NewFadesAnnounce(28732, 3)
local warnEnrageSoon		= mod:NewSoonAnnounce(28131, 3)
local warnEnrageNow			= mod:NewSpellAnnounce(28131, 4)

local specWarnEnrage		= mod:NewSpecialWarningDefensive(28131, nil, nil, nil, 3, 2)
local specWarnGTFO			= mod:NewSpecialWarningGTFO(28794, nil, nil, nil, 1, 8)

local timerEmbrace			= mod:NewBuffActiveTimer(30, 28732, nil, nil, nil, 6)
local timerEnrage			= mod:NewCDTimer(60, 28131, nil, nil, nil, 6)
local timerPoisonVolley		= mod:NewNextTimer(12, 54098, nil, nil, nil, 5)

mod.vb.enraged = false

function mod:OnCombatStart(delay)
	timerEnrage:Start(-delay)
	warnEnrageSoon:Schedule(55 - delay)
	timerPoisonVolley:Start(-delay)
	self.vb.enraged = false
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(28798, 54100) then			-- Frenzy
		self.vb.enraged = true
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnEnrage:Show()
			specWarnEnrage:Play("defensive")
		else
			warnEnrageNow:Show()
		end
	elseif args:IsSpellID(28732, 54097)	and args:GetDestCreatureID() == 15953 and self:AntiSpam(5) then	-- Widow's Embrace
		warnEmbraceExpire:Cancel()
		warnEmbraceExpired:Cancel()
		warnEnrageSoon:Cancel()
		timerEnrage:Stop()
		if self.vb.enraged then
			timerEnrage:Start()
			warnEnrageSoon:Schedule(45)
		end
		timerEmbrace:Start()
		warnEmbraceActive:Show()
		warnEmbraceExpire:Schedule(25)
		warnEmbraceExpired:Schedule(30)
		self.vb.enraged = false
	elseif args:IsSpellID(28794, 54099) and args:IsPlayer() then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(28796, 54098) then -- Poison Bolt Volley
		timerPoisonVolley:Start(10)
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 15953 then
		warnEnrageSoon:Cancel()
		warnEmbraceExpire:Cancel()
		warnEmbraceExpired:Cancel()
	end
end