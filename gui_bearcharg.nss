// Charge Ursine
#include "ginc_bearclass"
void main()
{
  if (GetLocalInt(OBJECT_SELF, "IS_BEAR_FORM"))
  {
    object oCaster = OBJECT_SELF;
    int nBearLevel = GetLevelByClass(188, oCaster);
    int nSpeedBoost = 33;
    float fDuration = 9.0;
    if (nBearLevel >= 5 && nBearLevel <= 9) {
      nSpeedBoost = 25;
      fDuration = 7.0;
    } else if (nBearLevel >= 1 && nBearLevel <= 4) {
      nSpeedBoost = 20;
      fDuration = 5.0;
    }

    // Vérifie si la capacité est en cooldown
    int nCurrentTime = GetTimeStamp();
    int nLastUsed = GetLocalInt(oCaster, "CHARGE_LAST_USED");

    if (nCurrentTime - nLastUsed < 12)
    {
      int nCooldownLeft = 12 - (nCurrentTime - nLastUsed);
      SendMessageToPC(oCaster, "La capacité est en cooldown. Temps restant : " + IntToString(nCooldownLeft) + " secondes.");
      return;
    }

    // Applique l'augmentation de vitesse
    effect eSpeed = EffectMovementSpeedIncrease(nSpeedBoost);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSpeed, oCaster, fDuration);

    // Applique l'effet visuel de charge
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_HIT_SPELL_ILLUSION), oCaster);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_HIT_BARD_INS_SLOWING), oCaster);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_DUR_SACRED_FLAMES), oCaster, fDuration);

    // Enregistre l'heure actuelle comme dernier temps d'utilisation
    SetLocalInt(oCaster, "CHARGE_LAST_USED", nCurrentTime);

    SendMessageToPC(oCaster, "Vous sentez la terre vibrer sous l'impact accéléré de vos pattes. Votre élan s'accroît.");
    SetGUIObjectDisabled(oCaster, "SCREEN_BEAR_GUI", "BEAR_CHARGE", 1);
    DelayCommand(12.0, SetGUIObjectDisabled(oCaster, "SCREEN_BEAR_GUI", "BEAR_CHARGE", 0));
  }
}