return {
    operations = {
        [1] = { type = "insertAfter", after = "if not serverWorld:clientWithTribeIDHasSeenTribeID(tribeIDPlayer, tribeIDNomad) then", 
            string = "\r\n                serverGOM:nonFollowerApproached(tribeIDPlayer, nomadID)\r\n"}
    }
}