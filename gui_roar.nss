// Rage Écrasante
#include "ginc_bearclass"
void main()
{
  if (GetLocalInt(OBJECT_SELF, "IS_BEAR_FORM"))
  {
    object oCaster = OBJECT_SELF;
    object oTarget = GetAttackTarget(oCaster); // Récupère la cible actuelle du personnage
    int nCurrentTime = GetTimeStamp();

    // Récupère le dernier temps d'utilisation de la capacité
    int nLastUsed = GetLocalInt(oCaster, "KNOCKDOWN_LAST_USED");

    // Si moins de 12 secondes se sont écoulées, la capacité est en cooldown
    if (nCurrentTime - nLastUsed < 12)
    {
      int nCooldownLeft = 12 - (nCurrentTime - nLastUsed);
      SendMessageToPC(oCaster, "La capacité est en cooldown. Temps restant : " + IntToString(nCooldownLeft) + " secondes.");
      return;
    }

    if (GetIsObjectValid(oTarget))
    {
      // Applique l'effet visuel de rage furieuse sur le lanceur
      PlayCustomAnimation(OBJECT_SELF, "UnA_taunt", 0);
      effect eVisualEffect1 = EffectVisualEffect(VFX_HIT_SPELL_SHOUT);
      effect eVisualEffect2 = EffectVisualEffect(VFX_HIT_AURORA_CHAIN);
      effect eVisualEffect3 = EffectVisualEffect(VFX_HIT_SPELL_INFLICT_6);
      ApplyEffectToObject(DURATION_TYPE_INSTANT, eVisualEffect1, oCaster);
      ApplyEffectToObject(DURATION_TYPE_INSTANT, eVisualEffect2, oCaster);
      ApplyEffectToObject(DURATION_TYPE_INSTANT, eVisualEffect3, oCaster, 2.0);
      DelayCommand(0.9, ApplyEffectToObject(DURATION_TYPE_INSTANT, eVisualEffect3, OBJECT_SELF));
      DelayCommand(0.9, ApplyEffectToObject(DURATION_TYPE_INSTANT, eVisualEffect2, OBJECT_SELF));
      DelayCommand(0.9, ApplyEffectToObject(DURATION_TYPE_INSTANT, eVisualEffect1, OBJECT_SELF));

      // Applique l'effet Knockdown
      // Forme d'effet : une sphère autour du lanceur
      float fRadius = 6.0; // Rayon de l'effet en mètres
      int nBearLevel = GetLevelByClass(188, oCaster);
      if (nBearLevel >= 5 && nBearLevel <= 9) {
        fRadius = 4.0;
      } else if (nBearLevel >= 1 && nBearLevel <= 4) {
        fRadius = 2.5;
      }
      location lCaster = GetLocation(oCaster);
      object oTarget = GetFirstObjectInShape(SHAPE_SPHERE, fRadius, lCaster, TRUE);

      while (GetIsObjectValid(oTarget))
      {
        // Vérifie que la cible est ennemie
        if (GetFactionEqual(oCaster, oTarget) == FALSE)
        {
          effect eKnockdown = EffectKnockdown();
          ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eKnockdown, oTarget, 6.0);
        }

        oTarget = GetNextObjectInShape(SHAPE_SPHERE, fRadius, lCaster, TRUE);
      }

      // Enregistre l'heure actuelle comme dernier temps d'utilisation
      SetLocalInt(oCaster, "KNOCKDOWN_LAST_USED", nCurrentTime);

      SendMessageToPC(oCaster, "Votre rugissement éclate avec la fureur de mille hivers ! La terre gémit sous votre rage ursine, et l'impact renverse tous ceux qui osent vous défier.");
      SetGUIObjectDisabled(oCaster, "SCREEN_BEAR_GUI", "BEAR_BUTTON", 1);
      DelayCommand(12.0, SetGUIObjectDisabled(oCaster, "SCREEN_BEAR_GUI", "BEAR_BUTTON", 0));
    }
    else
    {
      SendMessageToPC(oCaster, "Aucune cible valide pour Rage Écrasante.");
    }
  }
}