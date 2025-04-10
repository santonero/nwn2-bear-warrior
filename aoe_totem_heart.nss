const int CONCENTRATION_PENALTY = 5;
const int ATTACK_PENALTY = 2;
const float DEBUFF_DURATION = 1.6f;

void main()
{
  object oAoE = OBJECT_SELF;
  object oCreator = GetAreaOfEffectCreator(oAoE);

  object oTarget = GetFirstInPersistentObject(oAoE, OBJECT_TYPE_CREATURE);
  while (GetIsObjectValid(oTarget))
  {
    if (GetIsEnemy(oTarget, oCreator))
    {
      effect eConc = EffectSkillDecrease(SKILL_CONCENTRATION, CONCENTRATION_PENALTY);
      effect eAtk = EffectAttackDecrease(ATTACK_PENALTY);
      effect eLink = EffectLinkEffects(eConc, eAtk);

      // Le créateur de cet effet sera oAoE
      ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oTarget, DEBUFF_DURATION);
    }
    oTarget = GetNextInPersistentObject(oAoE, OBJECT_TYPE_CREATURE);
  }
}