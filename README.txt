================== Am�liorations ==================
01/06/2014 - Alexandre Lefort, Martin de Gourcuff, Edouard Leurent

=== InputProcessing ===
- Impl�mentation d'un Extended Kalman Filter pour estimer la position et l'orientation en recalant l'odom�trie par la vision
- Impl�mentation d'un Unscented Kalman Filter dans le m�me but, plus efficace que l'EKF pour recaler apr�s une d�rive importante (si on rajoute du bruit dans les encodeurs, par exemple), mais plus lourd en temps de calcul.
- Le recalage par EKF/UKF utilise toutes les zones vues par la cam�ra, et non plus juste la destination comme dans la simulation originale
- Prise en compte du d�lai de la cam�ra (0.3s) dans l'incorporation des mesures de l'EKF/UKF
- Commande de distance envoy�e en relatif pour g�rer les d�passements et demis-tours
- Rotation pendant l'attente � une zone pour s'orienter vers la prochaine

=== Controller === 
- R�glage des gains plus agressif
- Priorisation de la commande d'angle par saturation dynamique de la commande de distance au maximum possible permettant d'imposer le diff�rentiel de la commande de bearing
- Ajout de termes int�graux en distance et en angle pour r�soudre les blocages � proximit� d'une cible (effort des roues dans la dead band, insuffisant pour avancer). 
  Le gain int�gral est brid� en angle afin de converger plus rapidement et d'�viter le ph�nom�ne de wind-up
  Le gain int�gral en distance est mis � 0 pour le moment
- Ajout d'un terme d�riv� en angle � l'arr�t, pour limiter les d�passements
- Deux jeux de gains diff�rents pour le PID del'angle en fonction de l'�tat du robot (� l'arr�t sur un site ou en mouvement)

=== Strat�gie ===
- Solveur du voyageur de commerce par algorithme g�n�tique, qu'on ex�cute � la place de changeSitesOrder.m pour trouver le plus court chemin 
  Pour ce faire il suffit de lancer le script matlab/utilities/computeTSPSitesOrder.m
