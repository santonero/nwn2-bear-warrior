// ginc_bearclass.nss
// Include file pour la gestion de l'état de la forme d'ours (GUI et flags)
// *****************************************************************************
// CheckBearFormStateOnEvent
// *****************************************************************************
// But : Vérifie l'état réel de la transformation en ours (présence de l'effet
//       approprié au niveau) et synchronise la GUI et les flags locaux.
//       À appeler depuis OnClientEnter, OnRest, OnPlayerDeath/Respawn.
// *****************************************************************************
void CheckBearFormStateOnEvent(object oPC)
{
  int nBearWarrior = GetHasFeat(2871, oPC, TRUE);
  if (nBearWarrior)
  {
    // Vérifications initiales de l'objet passé
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC) || GetIsDM(oPC)) return;
    // --- Étape 1: Déterminer le niveau du joueur dans la classe Guerrier Ours ---
    int nBearLevel = GetLevelByClass(188, oPC);

    // --- Étape 2: Déterminer quel type de polymorph on devrait chercher ---
    int nExpectedPolyType = -1; // Valeur invalide par défaut

    if (nBearLevel >= 10) {
        nExpectedPolyType = 210;
    } else if (nBearLevel >= 5) {
        nExpectedPolyType = 209;
    } else if (nBearLevel >= 1) {
        nExpectedPolyType = 208;
    }

    // --- Étape 3: L'effet Polymorph attendu est-il réellement présent ? ---
    int bHasBearEffect = FALSE;
    if (nExpectedPolyType != -1)
    {
      effect eCheck = GetFirstEffect(oPC);
      while(GetIsEffectValid(eCheck))
      {	if (GetEffectType(eCheck) == EFFECT_TYPE_POLYMORPH)
        SendMessageToPC(oPC, IntToString(GetEffectInteger(eCheck, 0)));
          // Vérifier Type, Sous-Type spécifique attendu pour le niveau, et Créateur
          if (GetEffectType(eCheck) == EFFECT_TYPE_POLYMORPH &&
            GetEffectInteger(eCheck, 0) == nExpectedPolyType &&
            GetEffectCreator(eCheck) == oPC)
          {
            bHasBearEffect = TRUE;
            break; // Trouvé, on arrête la boucle
          }
          eCheck = GetNextEffect(oPC);
      }
    }

    // --- Étape 4: Vérifier l'état du flag local ---
    int bHasBearFlag = GetLocalInt(oPC, "IS_BEAR_FORM");

    // --- Étape 5: Logique de Synchronisation ---
    if (bHasBearEffect)
    {
      // ----- CAS 1: Le joueur EST en forme d'ours (l'effet approprié a été trouvé) -----
      if (!bHasBearFlag)
      {
        SetLocalInt(oPC, "IS_BEAR_FORM", TRUE);
      }
      int bModal = FALSE;
      DisplayGuiScreen(oPC, "SCREEN_BEAR_GUI", bModal, "bear_gui.xml");
    }
    else
    {
      // ----- CAS 2: Le joueur N'EST PAS en forme d'ours (pas d'effet approprié trouvé) -----
      if (bHasBearFlag) // Si le flag dit qu'on est en ours alors qu'on ne devrait pas...
      {
        // ... Nettoyage immédiat.
        CloseGUIScreen(oPC, "SCREEN_BEAR_GUI");
        DeleteLocalInt(oPC, "IS_BEAR_FORM");
        DeleteLocalInt(oPC, "CURRENT_RAGE_ID");
      }
      // Si le flag est déjà FALSE et qu'on n'a pas trouvé l'effet, tout est cohérent.
    }
  }
}

int GetTimeStamp()
{
  int minsperhour = FloatToInt(HoursToSeconds(1))/60;
  int time = GetTimeSecond() + (GetTimeMinute()*60) + ((GetTimeHour()*minsperhour)*60);
  int secondsperday = (24*minsperhour)*60;
  int secondspermonth = secondsperday*28;
  int secondsperyear = secondspermonth*12;
  return time + (GetCalendarYear()*secondsperyear) + (GetCalendarMonth()*secondspermonth) + (GetCalendarDay()*secondsperday);
}