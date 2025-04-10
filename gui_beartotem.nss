// Manifestation du Totem
#include "ginc_bearclass"
// --- Constantes de Configuration ---
const int nCooldown = 180;
const float fCooldown = 180.0;
// Nom de la variable locale pour suivre le cooldown (stockera le timestamp)
const string TOTEM_LAST_USED = "TOTEM_LAST_USED";

void main()
{
  if (GetLocalInt(OBJECT_SELF, "IS_BEAR_FORM"))
  {
  	float fDuration = 12.0;
    object oPC = OBJECT_SELF;
    int nBearLevel = GetLevelByClass(188, oPC);
    if (nBearLevel >= 5 && nBearLevel <= 9) {
      fDuration = 9.0;
    } else if (nBearLevel >= 1 && nBearLevel <= 4) {
      fDuration = 6.0;
    }

    // --- Vérification du Cooldown ---
    int nNow = GetTimeStamp();
    int nLastUsed = GetLocalInt(oPC, TOTEM_LAST_USED);

    if ((nNow - nLastUsed) < nCooldown)
    {
      int nCooldownLeft = nCooldown - (nNow - nLastUsed);
      // S'assurer que le temps restant affiché n'est pas négatif si le timestamp a eu un problème
      if (nCooldownLeft < 0) nCooldownLeft = 0;
      SendMessageToPC(oPC, "Manifestation du Totem est en rechargement pour encore " + IntToString(nCooldownLeft) + " secondes.");
      return;
    }

    // --- NETTOYAGE DES EFFETS EXISTANTS ---
    effect eCurrentEffect = GetFirstEffect(oPC);
    while (GetIsEffectValid(eCurrentEffect))
    {
      int nEffectType = GetEffectType(eCurrentEffect);

      if (nEffectType == EFFECT_TYPE_PARALYZE ||
          nEffectType == EFFECT_TYPE_STUNNED ||
          nEffectType == EFFECT_TYPE_DAZED ||
          nEffectType == EFFECT_TYPE_FRIGHTENED ||
          nEffectType == EFFECT_TYPE_DOMINATED ||
          nEffectType == EFFECT_TYPE_CHARMED ||
          nEffectType == EFFECT_TYPE_JARRING ||
          nEffectType == EFFECT_TYPE_MESMERIZE ||
          nEffectType == EFFECT_TYPE_CONFUSED ||
          nEffectType == EFFECT_TYPE_ENTANGLE ||
          nEffectType == EFFECT_TYPE_MOVEMENT_SPEED_DECREASE ||
          nEffectType == EFFECT_TYPE_SLOW ||
          nEffectType == EFFECT_TYPE_SLEEP
          )
      {
        RemoveEffect(oPC, eCurrentEffect);
      }
      eCurrentEffect = GetNextEffect(oPC);
    }

    effect eImmunityMind = EffectImmunity(IMMUNITY_TYPE_MIND_SPELLS);
    effect eImmunityParalysis = EffectImmunity(IMMUNITY_TYPE_PARALYSIS);
    effect eImmunityEntangle = EffectImmunity(IMMUNITY_TYPE_ENTANGLE);
    effect eImmunitySlow = EffectImmunity(IMMUNITY_TYPE_MOVEMENT_SPEED_DECREASE);
    effect eImmunityStun = EffectImmunity(IMMUNITY_TYPE_STUN);
    effect eImmunityDaze = EffectImmunity(IMMUNITY_TYPE_SLOW);

    // *** Création de l'effet Area of Effect ***
    // Utilise l'ID de base pour forme/rayon, mais surcharge les scripts et ajoute un tag.
    effect eAoE = EffectAreaOfEffect(19, "aoe_totem_enter", "aoe_totem_heart", "aoe_totem_exit", "TotemInstableAoEObject");
    effect eVFX_Duration = EffectVisualEffect(VFX_SPELL_DUR_BODY_SUN);

    effect eLink = EffectLinkEffects(eImmunityMind, eImmunityParalysis);
    eLink = EffectLinkEffects(eLink, eImmunityEntangle);
    eLink = EffectLinkEffects(eLink, eImmunitySlow);
    eLink = EffectLinkEffects(eLink, eImmunityStun);
    eLink = EffectLinkEffects(eLink, eImmunityDaze);
    eLink = EffectLinkEffects(eLink, eAoE); // Lier l'effet AoE
    eLink = EffectLinkEffects(eLink, eVFX_Duration);

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oPC, fDuration);
    SetLocalInt(oPC, TOTEM_LAST_USED, nNow);

    SendMessageToPC(oPC, "Les doutes disparaissent. Vous êtes inarrêtable. Le terrain se charge d'une énergie totémique instable qui perturbe vos ennemis.");

    SetGUIObjectDisabled(oPC, "SCREEN_BEAR_GUI", "BEAR_TOTEM", 1);
    DelayCommand(fCooldown, SetGUIObjectDisabled(oPC, "SCREEN_BEAR_GUI", "BEAR_TOTEM", 0));
  }
}