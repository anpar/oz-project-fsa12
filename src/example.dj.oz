% Brabanconne
local
   MainDroite = [etirer(facteur:0.5 g4) etirer(facteur:0.75 e4) etirer(facteur:0.25 f4) %1
		 g4 etirer(facteur:0.75 a4) etirer(facteur:0.25 b4) etirer(facteur:0.75 c5) etirer(facteur:0.25 b4) etirer(facteur:0.75 c5) etirer(facteur:0.25 e5) %2
		 etirer(facteur:1.5 g4) etirer(facteur:0.25 b4) etirer(facteur:0.25 a4) etirer(facteur:0.5 g4) etirer(facteur:0.5 silence) etirer(facteur:0.75 b4) etirer(facteur:0.25 c5) %3
		 d5 etirer(facteur:0.75 d5) etirer(facteur:0.25 d5) etirer(facteur:0.75 d5) etirer(facteur:0.125 e5) etirer(facteur:0.125 d5) etirer(facteur:0.75 c5) etirer(facteur:0.25 b4) %4
		 etirer(facteur:0.5 c5) etirer(facteur:0.5 silence) etirer(facteur:1.75 e5) etirer(facteur:0.25 b4) etirer(facteur:0.75 c5) etirer(facteur:0.25 a4) %5
		 g4 etirer(facteur:0.75 a4) etirer(facteur:0.25 b4) etirer(facteur:0.75 c5) etirer(facteur:0.25 b4) etirer(facteur:0.75 c5) etirer(facteur:0.25 d5) %6
		 etirer(facteur:1.5 b4) etirer(facteur:0.25 d5) etirer(facteur:0.25 c5) etirer(facteur:0.5 b4) etirer(facteur:0.5 silence) etirer(facteur:0.75 b4) etirer(facteur:0.25 a4) %7
		 g4 etirer(facteur:0.75 g4) etirer(facteur:0.25 b4) d5 etirer(facteur:0.75 c5) etirer(facteur:0.25 a4) %8
		 etirer(facteur:2.0 g4) %9
		]

   Tune = [b b c5 d5 d5 c5 b a g g a b]
   End1 = [etirer(facteur:1.5 b) etirer(facteur:0.5 a) etirer(facteur:2.0 a)]
   End2 = [etirer(facteur:1.5 a) etirer(facteur:0.5 g) etirer(facteur:2.0 g)]
   Interlude = [a a b g a etirer(facteur:0.5 [b c5])
                    b g a etirer(facteur:0.5 [b c5])
                b a g a etirer(facteur:2.0 d) ]

   % Ceci n'est pas une musique
   Partition = [echo(delai:1.0 decadence:0.5 repetition:4 etirer(facteur:0.2 [Tune End1 Tune End2 Interlude Tune End2]))]
in
   % Ceci est une musique :-)
   [echo(delai:1.0 decadence:0.5 repetition:4 [partition(instrument(nom:bee_long [etirer(facteur:0.5 MainDroite)]))])]
end