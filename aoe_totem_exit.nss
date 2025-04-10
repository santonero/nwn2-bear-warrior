void main()
{
  object oAoE = OBJECT_SELF;
  object oLeaving = GetExitingObject();

  if (GetIsObjectValid(oLeaving))
  {
    effect eEffect = GetFirstEffect(oLeaving);
    while (GetIsEffectValid(eEffect))
    {
      int nEffectType = GetEffectType(eEffect);
      // Vérifier si c'est un des types de debuff que nous appliquons
      if (nEffectType == EFFECT_TYPE_SKILL_DECREASE || nEffectType == EFFECT_TYPE_ATTACK_DECREASE)
      {
        // Vérifier si le créateur de cet effet est BIEN notre AoE
        if (GetEffectCreator(eEffect) == oAoE)
        {
          RemoveEffect(oLeaving, eEffect);
        }
      }
      eEffect = GetNextEffect(oLeaving);
    }
  }
}