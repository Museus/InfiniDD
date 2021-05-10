--[[
    InfiniDD v1.0
    Author:
        Museus (Discord: Museus#7777)

    Gives the player an "Infinite DD" that will result in a delayed
    resurrection after dying.
]]
ModUtil.RegisterMod("InfiniDD")

local config = {
    Immortal = true, -- If true, player will have an InfiniDD
    TimePenalty = 30, -- Duration in seconds to make player wait
    HealAmount = 1.0, -- Amount of health to heal player as decimal. (1 == 100%)
}
InfiniDD.config = config

function PenaltyBox(time)
    -- Add a SimSpeedChange to the table to specify that we're in the penalty box
    -- Using Fraction = 0 causes super weird graphical bugs, don't do it
    AddSimSpeedChange( "PenaltyBox", { Fraction = 0.001 , LerpTime = 0, Priority = true } )

    -- Hades _really_ wants to run at full speed, so constantly set the SimSpeed
    -- back down to 0.001
    for time_remaining = InfiniDD.config.TimePenalty,1,-1 do
        WaitOneSecond(time_remaining)
    end
    PrintUtil.destroyScreenAnchor("InfiniDDPenaltyCountdown")

    -- Remove the SimSpeedChange to bring everything back to normal
    RemoveSimSpeedChange("PenaltyBox", { LerpTime = 0.001 })
end

function WaitOneSecond(time_remaining)
    -- Just use PrintUtil to make the countdown
    PrintUtil.createOverlayLine(
        "InfiniDDPenaltyCountdown",
        time_remaining,
        {
            x_pos = 960,
            y_pos = 360,
            justification = "center",
            font_size = 128,
        }
    )

    AdjustSimulationSpeed({ Fraction = 0.001, LerpTime = 0 })
    waitScreenTime(1)
end

-- Scripts/RoomManager.lua : 1874
ModUtil.WrapBaseFunction("StartRoom", function ( baseFunc, currentRun, currentRoom )
    PrintUtil.showModdedWarning()

    baseFunc(currentRun, currentRoom)
end, InfiniDD)

-- Scripts/UIScripts.lua : 145
ModUtil.WrapBaseFunction("ShowCombatUI", function ( baseFunc, flag )
    PrintUtil.showModdedWarning()

    baseFunc(flag)
end, InfiniDD)

-- Scripts/RunManager.lua : 48
ModUtil.WrapBaseFunction("InitHeroLastStands", function(baseFunc, newHero)
    -- Add infinite DD, use SD symbol
    if InfiniDD.config.Immortal then
        AddLastStand({
            Name = "InfiniDD",
            Unit = newHero,
            IncreaseMax = true,
            Icon = "ExtraLifeReplenish",
            WeaponName = "LastStandMetaUpgradeShield",
            HealFraction = InfiniDD.config.HealAmount,
            Silent = true
        })
    end

    baseFunc(newHero)
end, InfiniDD)

-- Scripts/CombatPresentation.lua : 870
ModUtil.WrapBaseFunction("PlayerLastStandPresentationEnd", function( baseFunc )
    if InfiniDD.config.Immortal and not HasLastStand(CurrentRun.Hero) then
        -- Re-add InfiniDD any time it is lost
        AddLastStand({
            Name = "InfiniDD",
            Unit = CurrentRun.Hero,
            Icon = "ExtraLifeReplenish",
            WeaponName = "LastStandMetaUpgradeShield",
            HealFraction = InfiniDD.config.HealAmount,
            Silent = true
        })
        RecreateLifePips()

        -- Spin up a thread to handle the Penalty Box
        thread(PenaltyBox, InfiniDD.config.TimePenalty)
    end

    baseFunc()
end, InfiniDD)


ModUtil.WrapBaseWithinFunction("NoLastStandRegeneration", "HasLastStand", function( baseFunc, unit )
    if TableLength(unit.LastStands) == 1 and unit.LastStands[1].Name == "InfiniDD" then
        return false
    else
        return baseFunc(unit)
    end
end, InfiniDD)
