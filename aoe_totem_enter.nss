const int CONCENTRATION_PENALTY = 5;
const int ATTACK_PENALTY = 2;

void main()
{
  object oAoE = OBJECT_SELF;
  object oEntering = GetEnteringObject();
  object oCreator = GetAreaOfEffectCreator(oAoE);

  if (GetIsObjectValid(oEntering) && GetIsEnemy(oEntering, oCreator))
  {
    effect eConc = EffectSkillDecrease(SKILL_CONCENTRATION, CONCENTRATION_PENALTY);
    effect eAtk = EffectAttackDecrease(ATTACK_PENALTY);
    effect eVfx = EffectVisualEffect(VFX_HIT_SPELL_CASTIGATE);
    effect eLink = EffectLinkEffects(eConc, eAtk);
    eLink = EffectLinkEffects(eLink, eVfx);

    // Appliquer pour une courte durée (sera rafraîchi par le heartbeat)
    // Le créateur de cet effet sera oAoE
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oEntering, 1.6f);
  }
}