//::///////////////////////////////////////////////
//:: Barbarian Rage
//:: NW_S1_BarbRage
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    The Str and Con of the Barbarian increases,
    Will Save are +2, AC -2.
    Greater Rage starts at level 15.
*/
//:://////////////////////////////////////////////
//:: Created By: Preston Watamaniuk
//:: Created On: Aug 13, 2001
//:://////////////////////////////////////////////
//:: AFW-OEI 04/12/2006: Made Greater and Mighty rage work as per 3.5 rules.
//:: 	Added fatigue after raging.
//::	Added Tireless Rage feat.
//:://////////////////////////////////////////////
//:: AFW-OEI 07/11/2007: New GetHasFeat() function call
//::	now returns false if a feat is not useable due to cooldown.
//::	So use new parameter to ignore remaining uses as we're merely doing
//::	an existence check.
//:: AFW-OEI 02/16/2007: Implement Epic Rage.
//:: AFW-OEI 06/25/2007: Implement Ice Troll Berserker.
//:: 2025: Implement Bear Warrior.

#include "x2_i0_spells"
#include "nwn2_inc_spells"
#include "cmi_ginc_chars"

void ApplyFatigue2(object oTarget, int nFatigueDuration, float fDelay = 0.0f);
void ApplyFatigue3(object oTarget, int nFatigueDuration);

effect ProcessItemAC(object oItemToProcess, int nACTypeToApply)
{
	effect eACBonus;
	if (GetIsObjectValid(oItemToProcess))
	{
		itemproperty ip = GetFirstItemProperty(oItemToProcess);
		while (GetIsItemPropertyValid(ip))
		{
			if (GetItemPropertyType(ip) == ITEM_PROPERTY_AC_BONUS)
			{
				int nACBonus = GetItemPropertyCostTableValue(ip);
				if (nACBonus > 0)
				{
					eACBonus = EffectACIncrease(nACBonus, nACTypeToApply);
				}
			}
			ip = GetNextItemProperty(oItemToProcess);
		}
	}
	return eACBonus;
}

void CheckAndCloseGUI(int nRageID)
{
	if (GetIsObjectValid(OBJECT_SELF) && GetLocalInt(OBJECT_SELF, "CURRENT_RAGE_ID") == nRageID)
	{
		CloseGUIScreen(OBJECT_SELF, "SCREEN_BEAR_GUI");
		SetLocalInt(OBJECT_SELF, "IS_BEAR_FORM", FALSE);
	}
}

void main()
{
	// If you're already in a rage, don't apply effects again
    if(!GetHasFeatEffect(FEAT_BARBARIAN_RAGE))
    {
		// JLR - OEI 06/21/05 NWN2 3.5
		// AFW-OEI 04/11/2006: Implement Mighty Rage.
        int nIncrease;
        int nSave;
	int nNaturalAC = 0;

	int nBearWarrior = GetHasFeat(2871, OBJECT_SELF, TRUE);
	int nBearStrength;
	int nBearConstitution;
	int nBearDexterity;
	int nPoly;
	int nEnhancementBonus;
	int nBaseAC;
	effect eRegen;

	object oRing1Old;
	object oRing2Old;
	object oAmuletOld;
	object oBeltOld;
	object oChestOld;
	object oHeadOld;
	object oCloakOld;
	object oGloves;
	object oWeaponOld;

        if (GetHasFeat(FEAT_EPIC_BARBARIAN_RAGE, OBJECT_SELF, TRUE))    // Epic Rage
        {
            nIncrease = 10;
            nSave = 8;      // Intentional extra Will boost for Epic Barbs.
			nNaturalAC = 8;
        }
		else if (GetHasFeat(FEAT_BARBARIAN_RAGE7, OBJECT_SELF, TRUE))	// Mighty Rage
		{
			//SpeakString("nw_s1_barbrage: Has FEAT_BARBARIAN_RAGE7.");	// DEBUG
			nIncrease = 8;
			nSave = 4;
			nNaturalAC = 6;
		}
        else if (GetHasFeat(FEAT_BARBARIAN_RAGE4, OBJECT_SELF, TRUE))	// Greater Rage
        {
			//SpeakString("nw_s1_barbrage: Has FEAT_BARBARIAN_RAGE4.");	// DEBUG
            nIncrease = 6;
            nSave = 3;
			nNaturalAC = 4;
        }
        else	// Regular old rage
        {
			//SpeakString("nw_s1_barbrage: Default bonuses.");	// DEBUG
            nIncrease = 4;
            nSave = 2;
			nNaturalAC = 2;
        }

	if (nBearWarrior) //bear form
	{
		if (GetLevelByClass(188) >= 10) //dire bear
		{
			nBearStrength = 12;
			nBearConstitution = 8;
			nBearDexterity = 2;
			nPoly = 210;
			nNaturalAC = 7;
      nEnhancementBonus = 4;
			nBaseAC = 8;
			eRegen = EffectRegenerate(4, 6.0);
		}
		else if (GetLevelByClass(188) >= 5) //brown bear
		{
			nBearStrength = 10;
			nBearConstitution = 8;
			nBearDexterity = 2;
			nPoly = 209;
			nNaturalAC = 5;
      nEnhancementBonus = 3;
			nBaseAC = 5;
			eRegen = EffectRegenerate(3, 6.0);
		}
		else //black bear
		{
			nBearStrength = 8;
			nBearConstitution = 4;
			nBearDexterity = 2;
			nPoly = 208;
			nNaturalAC = 2;
      nEnhancementBonus = 2;
			nBaseAC = 2;
			eRegen = EffectRegenerate(2, 6.0);
		}
		nSave = 2;
	}

        //Determine the duration by getting the con modifier after being modified
        int nRageDuration = 3 + GetAbilityModifier(ABILITY_CONSTITUTION) + (nIncrease/2);
				if (nBearWarrior) { nRageDuration = 3 + GetAbilityModifier(ABILITY_CONSTITUTION) + (nBearConstitution/2); }
        if (GetHasFeat(FEAT_EXTEND_RAGE))
        {
            nRageDuration += 5;
			if (GetHasFeat(FEAT_EXTEND_RAGE_II))
			{
				nRageDuration += 5;
				if (GetHasFeat(FEAT_EXTEND_RAGE_III))
				{
					nRageDuration += 5;
					if (GetHasFeat(FEAT_EXTEND_RAGE_IV))
					{
						nRageDuration += 5;
					}
				}
			}
        }
		float fRageDuration = RoundsToSeconds(nRageDuration);

		// Add Indomitable Will save bonus, if you have it
		if (GetHasFeat(FEAT_INDOMITABLE_WILL, OBJECT_SELF, TRUE))
		{
			effect eWill = EffectSavingThrowIncrease(SAVING_THROW_WILL, 4, SAVING_THROW_TYPE_MIND_SPELLS);
			eWill = SetEffectSpellId(eWill, -GetSpellId());
			eWill = ExtraordinaryEffect(eWill);
			ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eWill, OBJECT_SELF, fRageDuration);
		}

		if (GetHasFeat(FEAT_BARB_WHIRLWIND_FRENZY))
		{
	        if (nRageDuration > 0)
	        {

				effect eAB = EffectAttackDecrease(2);
				effect eAtks = EffectModifyAttacks(1);

				// Put together the positive rage effects
		        effect eStr  = EffectAbilityIncrease(ABILITY_STRENGTH, nIncrease);
		        effect eSave = EffectSavingThrowIncrease(SAVING_THROW_REFLEX, nIncrease/2);
		        effect eAC   = EffectACIncrease(nIncrease/2, AC_DODGE_BONUS);
		        effect eDur  = EffectVisualEffect( VFX_DUR_SPELL_RAGE );

		        effect eLink = EffectLinkEffects(eStr, eSave);
		        eLink = EffectLinkEffects(eLink, eAC);
		        eLink = EffectLinkEffects(eLink, eDur);

				if (!GetHasSpellEffect(SPELL_HASTE,OBJECT_SELF))
				{
						eLink = EffectLinkEffects(eLink, eAB);
						eLink = EffectLinkEffects(eLink, eAtks);
				}

				effect eNaturalAC;
				if (GetHasFeat(FEAT_ICE_TROLL_BERSERKER, OBJECT_SELF, TRUE))
				{
					eNaturalAC = EffectACIncrease(nNaturalAC, AC_NATURAL_BONUS);
					eLink = EffectLinkEffects(eLink, eNaturalAC);
				}

		     	eLink = ExtraordinaryEffect(eLink);	 //Make effect extraordinary
		        PlayVoiceChat(VOICE_CHAT_BATTLECRY1);

				if ( PlayCustomAnimation(OBJECT_SELF, "sp_warcry", 0) )
				{
					//FloatingTextStringOnCreature( "I HAVE THE WARCRY ANIMATION!", OBJECT_SELF );
				}

				SignalEvent(OBJECT_SELF, EventSpellCastAt(OBJECT_SELF, SPELLABILITY_BARBARIAN_RAGE, FALSE));

	            //Apply the VFX impact and effects
	            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, OBJECT_SELF, fRageDuration);
	            //ApplyEffectToObject(DURATION_TYPE_INSTANT, eVis, OBJECT_SELF) ;


				if (GetHasFeat(FEAT_SHARED_FURY, OBJECT_SELF))
				{
					object oMyPet = GetAssociate(ASSOCIATE_TYPE_ANIMALCOMPANION, OBJECT_SELF);
					if (GetIsObjectValid(oMyPet))
	            		DelayCommand(0.1f, ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oMyPet, fRageDuration));
				}

		        // 2003-07-08, Georg: Rage Epic Feat Handling
		        CheckAndApplyEpicRageFeats(nRageDuration);

				// Unless you have Tireless Rage, you're going to feel it in the morning
				if (!GetHasFeat(FEAT_TIRELESS_RAGE, OBJECT_SELF, TRUE))
				{
					if (!GetHasFeat(FEAT_TIRELESS))
						// Start the fatigue logic half a second before the rage ends
						DelayCommand(fRageDuration - 0.5f, ApplyFatigue2(OBJECT_SELF, 5, 0.6f));	// Fatigue duration fixed to 5 rounds
				}
			}
		}
		else
		{
		// Apply rage bonuses, but only if your rage is going to last more than 0 rounds
        if (nRageDuration > 0)
        {
			// Put together the positive rage effects
		effect eLink;
	        effect eCon  = EffectAbilityIncrease(ABILITY_CONSTITUTION, nIncrease);
	        effect eStr  = EffectAbilityIncrease(ABILITY_STRENGTH, nIncrease);
	        effect eSave = EffectSavingThrowIncrease(SAVING_THROW_WILL, nSave);
	        effect eAC   = EffectACDecrease(2, AC_DODGE_BONUS);
	        effect eDur  = EffectVisualEffect( VFX_DUR_SPELL_RAGE );

	        eLink = EffectLinkEffects(eCon, eStr);

		if (nBearWarrior)
		{

			// Put together the positive rage effects
	        	eCon  = EffectAbilityIncrease(ABILITY_CONSTITUTION, nBearConstitution);
	        	eStr  = EffectAbilityIncrease(ABILITY_STRENGTH, nBearStrength);
	        	effect eDex  = EffectAbilityIncrease(ABILITY_DEXTERITY, nBearDexterity);
			effect eDur2 = EffectVisualEffect(VFX_DUR_POLYMORPH);
			effect eBaseAC = EffectACIncrease(nBaseAC, AC_DODGE_BONUS);
			effect eNaturalArmor = EffectACIncrease(nNaturalAC, AC_NATURAL_BONUS);


	        	eLink = EffectLinkEffects(eCon, eStr);
	        	eLink = EffectLinkEffects(eLink, eDex);
	        	eLink = EffectLinkEffects(eLink, eDur2);
						eLink = EffectLinkEffects(eLink, eBaseAC);
						eLink = EffectLinkEffects(eLink, eNaturalArmor);
						eLink = EffectLinkEffects(eLink, eRegen);
		}

	        eLink = EffectLinkEffects(eLink, eSave);
	        eLink = EffectLinkEffects(eLink, eAC);
	        eLink = EffectLinkEffects(eLink, eDur);

			effect eNaturalAC;
			if (GetHasFeat(FEAT_ICE_TROLL_BERSERKER, OBJECT_SELF, TRUE))
			{
				eNaturalAC = EffectACIncrease(nNaturalAC, AC_NATURAL_BONUS);
				eLink = EffectLinkEffects(eLink, eNaturalAC);
			}

			if (nBearWarrior)
			{
				effect ePoly = EffectPolymorph(nPoly, TRUE, FALSE);
				eLink = EffectLinkEffects(eLink, ePoly);

				oRing1Old = GetItemInSlot(INVENTORY_SLOT_LEFTRING,OBJECT_SELF);
				oRing2Old = GetItemInSlot(INVENTORY_SLOT_RIGHTRING,OBJECT_SELF);
				oAmuletOld = GetItemInSlot(INVENTORY_SLOT_NECK,OBJECT_SELF);
				oBeltOld = GetItemInSlot(INVENTORY_SLOT_BELT,OBJECT_SELF);
				oChestOld = GetItemInSlot(INVENTORY_SLOT_CHEST,OBJECT_SELF);
				oHeadOld = GetItemInSlot(INVENTORY_SLOT_HEAD,OBJECT_SELF);
				oCloakOld = GetItemInSlot(INVENTORY_SLOT_CLOAK, OBJECT_SELF);
				oGloves = GetItemInSlot(INVENTORY_SLOT_ARMS, OBJECT_SELF);
				oWeaponOld = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND,OBJECT_SELF);
			}

	     	eLink = ExtraordinaryEffect(eLink);	 //Make effect extraordinary

			// Create the visual effect
	        //effect eVis = EffectVisualEffect(VFX_IMP_IMPROVE_ABILITY_SCORE); //Change to the Rage VFX

			// "Cast" rage
	        PlayVoiceChat(VOICE_CHAT_BATTLECRY1);

			if ( PlayCustomAnimation(OBJECT_SELF, "sp_warcry", 0) )
			{
				//FloatingTextStringOnCreature( "I HAVE THE WARCRY ANIMATION!", OBJECT_SELF );
			}


			SignalEvent(OBJECT_SELF, EventSpellCastAt(OBJECT_SELF, SPELLABILITY_BARBARIAN_RAGE, FALSE));

            //Apply the VFX impact and effects
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, OBJECT_SELF, fRageDuration);
						if (GetLevelByClass(188) >= 5)
						{
							ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_HIT_AOE_MAGIC), OBJECT_SELF);
							PlayCustomAnimation(OBJECT_SELF, "UnA_multiattack01", 0);
						}
            //ApplyEffectToObject(DURATION_TYPE_INSTANT, eVis, OBJECT_SELF) ;
				effect eHeal = EffectHeal(1);
				if ( GetCurrentHitPoints(OBJECT_SELF) > GetMaxHitPoints(OBJECT_SELF))
				{
					ApplyEffectToObject(DURATION_TYPE_INSTANT, eHeal, OBJECT_SELF);
				}
				if (GetHasFeat(FEAT_SHARED_FURY, OBJECT_SELF))
				{
					object oMyPet = GetAssociate(ASSOCIATE_TYPE_ANIMALCOMPANION, OBJECT_SELF);
					if (GetIsObjectValid(oMyPet))
	            		DelayCommand(0.1f, ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oMyPet, fRageDuration));
				}

	        // 2003-07-08, Georg: Rage Epic Feat Handling
	        CheckAndApplyEpicRageFeats(nRageDuration);

			if (nBearWarrior)
			{
				object oArmorNew = GetItemInSlot(INVENTORY_SLOT_CARMOUR,OBJECT_SELF);
				object oWeaponNew1 = GetItemInSlot(INVENTORY_SLOT_CWEAPON_B,OBJECT_SELF);
				object oWeaponNew2 = GetItemInSlot(INVENTORY_SLOT_CWEAPON_L,OBJECT_SELF);
				object oWeaponNew3 = GetItemInSlot(INVENTORY_SLOT_CWEAPON_R,OBJECT_SELF);

				IPWildShapeCopyItemProperties(oHeadOld,oArmorNew);
				IPWildShapeCopyItemProperties(oChestOld,oArmorNew);
				IPWildShapeCopyItemProperties(oRing1Old,oArmorNew);
				IPWildShapeCopyItemProperties(oRing2Old,oArmorNew);
				IPWildShapeCopyItemProperties(oAmuletOld,oArmorNew);
				IPWildShapeCopyItemProperties(oBeltOld,oArmorNew);
				IPWildShapeCopyItemProperties(oCloakOld,oArmorNew);

				// Transfert de CA
    		effect eCombinedLink;
				// --- Traitement de chaque slot ---
    		effect eSlotEffect; // Variable temporaire pour stocker l'effet retourné par ProcessItemAC

				// --- Tête (Head) ---
				eSlotEffect = ProcessItemAC(oHeadOld, AC_DEFLECTION_BONUS);
				eCombinedLink = eSlotEffect;

				// --- Torse (Chest) ---
				eSlotEffect = ProcessItemAC(oChestOld, AC_ARMOUR_ENCHANTMENT_BONUS);
				eCombinedLink = EffectLinkEffects(eCombinedLink, eSlotEffect);

				// --- Anneau 1 (Ring 1) ---
				eSlotEffect = ProcessItemAC(oRing1Old, AC_DEFLECTION_BONUS);
				eCombinedLink = EffectLinkEffects(eCombinedLink, eSlotEffect);

				// --- Anneau 2 (Ring 2) ---
				eSlotEffect = ProcessItemAC(oRing2Old, AC_DEFLECTION_BONUS);
				eCombinedLink = EffectLinkEffects(eCombinedLink, eSlotEffect);

				// --- Amulette (Amulet) ---
				eSlotEffect = ProcessItemAC(oAmuletOld, AC_NATURAL_BONUS);
				eCombinedLink = EffectLinkEffects(eCombinedLink, eSlotEffect);

				// --- Ceinture (Belt) ---
				eSlotEffect = ProcessItemAC(oBeltOld, AC_DEFLECTION_BONUS);
				eCombinedLink = EffectLinkEffects(eCombinedLink, eSlotEffect);

				// --- Cape (Cloak) ---
				eSlotEffect = ProcessItemAC(oCloakOld, AC_DEFLECTION_BONUS);
				eCombinedLink = EffectLinkEffects(eCombinedLink, eSlotEffect);

				// --- Application Finale ---
				ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCombinedLink, OBJECT_SELF, fRageDuration);

				int nEnhBonus = (nBearStrength-12)/2; //hack becaus str bonus only goes up to +12

				if	(nEnhBonus > 0)
				{
					itemproperty ipEnhancement = ItemPropertyEnhancementBonus(nEnhBonus+nEnhancementBonus);
					IPSafeAddItemProperty(oWeaponNew1, ipEnhancement, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
					IPSafeAddItemProperty(oWeaponNew2, ipEnhancement, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
					IPSafeAddItemProperty(oWeaponNew3, ipEnhancement, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
				}
				else
				{
					itemproperty ipEnhancement = ItemPropertyEnhancementBonus(nEnhancementBonus);
					IPSafeAddItemProperty(oWeaponNew1, ipEnhancement, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
					IPSafeAddItemProperty(oWeaponNew2, ipEnhancement, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
					IPSafeAddItemProperty(oWeaponNew3, ipEnhancement, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
				}

				// Application des bonus de dégâts gants ou arme
				int bDamageBonusFound = FALSE; // Indicateur pour savoir si un bonus de dégâts a été trouvé

				if (GetIsObjectValid(oGloves))
				{
					itemproperty ipGloveProperty = GetFirstItemProperty(oGloves);
					while (GetIsItemPropertyValid(ipGloveProperty))
					{
						if (GetItemPropertyType(ipGloveProperty) == ITEM_PROPERTY_DAMAGE_BONUS)
						{
							int nDamageType = GetItemPropertySubType(ipGloveProperty);
							int nBonus = GetItemPropertyCostTableValue(ipGloveProperty);

							// Ajout des bonus des gants aux nouvelles armes
							itemproperty ipNewDamage = ItemPropertyDamageBonus(nDamageType, nBonus);
							IPSafeAddItemProperty(oWeaponNew1, ipNewDamage, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
							IPSafeAddItemProperty(oWeaponNew2, ipNewDamage, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
							IPSafeAddItemProperty(oWeaponNew3, ipNewDamage, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);

							bDamageBonusFound = TRUE; // Un bonus de dégâts a été trouvé
						}
						ipGloveProperty = GetNextItemProperty(oGloves);
					}
				}

				if (!bDamageBonusFound && GetIsObjectValid(oWeaponOld))
				{
					itemproperty ipElemental = GetFirstItemProperty(oWeaponOld);
					while (GetIsItemPropertyValid(ipElemental))
					{
						if (GetItemPropertyType(ipElemental) == ITEM_PROPERTY_DAMAGE_BONUS)
						{
							int nDamageType = GetItemPropertySubType(ipElemental);
							int nBonus = GetItemPropertyCostTableValue(ipElemental);

							itemproperty ipNaturalDamage = ItemPropertyDamageBonus(nDamageType, nBonus);
							IPSafeAddItemProperty(oWeaponNew1, ipNaturalDamage, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
							IPSafeAddItemProperty(oWeaponNew2, ipNaturalDamage, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
							IPSafeAddItemProperty(oWeaponNew3, ipNaturalDamage, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
						}
						ipElemental = GetNextItemProperty(oWeaponOld);
					}
				}

				// Application des dons de specialisation unarmed
				if (GetHasFeat(138, OBJECT_SELF, TRUE))
				{
					int DmgSpecial = DAMAGE_BONUS_2;
					if (GetHasFeat(1169, OBJECT_SELF, TRUE))
					{
						DmgSpecial = DAMAGE_BONUS_4;
						if (GetHasFeat(668, OBJECT_SELF, TRUE))
						{
							DmgSpecial = DAMAGE_BONUS_6;
						}
					}
					effect eDamageIncrease = EffectDamageIncrease(DmgSpecial, DAMAGE_TYPE_BLUDGEONING);
					ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eDamageIncrease, OBJECT_SELF, fRageDuration);
				}

				int nRageID = Random(100000);
    		SetLocalInt(OBJECT_SELF, "CURRENT_RAGE_ID", nRageID);
				SetLocalInt(OBJECT_SELF, "IS_BEAR_FORM", TRUE);
				// display bear bar
				int bModal;
				DisplayGuiScreen(OBJECT_SELF, "SCREEN_BEAR_GUI", bModal, "bear_gui.xml");
				DelayCommand(fRageDuration + 0.5f, CheckAndCloseGUI(nRageID));	// close bear bar at end of rage

				// if	(GetLevelByClass(150) >= 5)
				// {
				// 	itemproperty ipOnHit = ItemPropertyOnHitProps(IP_CONST_ONHIT_STUN, IP_CONST_ONHIT_SAVEDC_16, IP_CONST_ONHIT_DURATION_75_PERCENT_1_ROUND);
				// 	IPSafeAddItemProperty(oWeaponNew2, ipOnHit, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
				// 	IPSafeAddItemProperty(oWeaponNew3, ipOnHit, 0.0, X2_IP_ADDPROP_POLICY_KEEP_EXISTING, FALSE, FALSE);
				// }
			}

			// Unless you have Tireless Rage, you're going to feel it in the morning
			if (!GetHasFeat(FEAT_TIRELESS_RAGE, OBJECT_SELF, TRUE))
			{
				if (!GetHasFeat(FEAT_TIRELESS))
					// Start the fatigue logic half a second before the rage ends
					DelayCommand(fRageDuration - 0.5f, ApplyFatigue2(OBJECT_SELF, 5, 0.6f));	// Fatigue duration fixed to 5 rounds
			}
				}
    }
    }
}

void ApplyFatigue2(object oTarget, int nFatigueDuration, float fDelay = 0.0f)
{
	//SpeakString("Entering ApplyFatigue");

	// Only apply fatigue ifyou're not resting.
	// This is to keep you from getting fatigued if you rest while raging.
	if( !GetIsResting() && (GetHasFeatEffect(FEAT_BARBARIAN_RAGE)) )
	{
		//SpeakString("Actually applying fatigue effect in ApplyFatigue");

		DelayCommand(fDelay, ApplyFatigue3(oTarget, nFatigueDuration));
	}
}

void ApplyFatigue3(object oTarget, int nFatigueDuration)
{
	if( !GetHasFeatEffect(FEAT_BARBARIAN_RAGE) )
	{
		// Create the fatigue penalty
		effect eFatigue = EffectCMIFatigue();

		float fFatigueDuration = RoundsToSeconds(nFatigueDuration);

		ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFatigue, oTarget, fFatigueDuration);
	}
}